# ── Auth Token ────────────────────────────────────────────────────────────────
# Generates a 64-char random auth token and creates the Secrets Manager secret.
# The secret is populated with the full connection bundle after the cluster is
# provisioned (see aws_secretsmanager_secret_version below).

module "secrets" {
  source = "./modules/secrets"

  name_prefix                 = local.name_prefix
  secret_recovery_window_days = var.secret_recovery_window_days
}

# ── Valkey Cluster ────────────────────────────────────────────────────────────
# ElastiCache Valkey replication group in the data VPC.
# Shared across blue and green EKS clusters — the data layer is never duplicated.
# Both clusters hit the same Valkey instance via data VPC peering.

module "valkey_cluster" {
  source = "./modules/valkey-cluster"

  name_prefix         = local.name_prefix
  data_vpc_id         = var.data_vpc_id
  subnet_ids          = local.active_data_subnets
  allowed_cidr_blocks = local.allowed_cidr_blocks

  engine_version             = var.engine_version
  node_type                  = var.node_type
  num_shards                 = var.num_shards
  replicas_per_shard         = var.replicas_per_shard
  cluster_mode_enabled       = local.cluster_mode_enabled
  automatic_failover_enabled = local.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  auth_token                 = module.secrets.auth_token
  at_rest_encryption_enabled = var.at_rest_encryption_enabled

  snapshot_retention_days = var.snapshot_retention_days
  snapshot_window         = var.snapshot_window
  maintenance_window      = var.maintenance_window
  apply_immediately       = var.apply_immediately
}

# ── Connection Bundle (Secrets Manager) ───────────────────────────────────────
# Write the full connection details into the secret after the cluster is up.
# ESO ExternalSecret in k8s-manifests pulls this as a K8s Secret into each
# namespace that needs Valkey access (e.g. Kong rate-limiting, RAG backend).
#
# Secret JSON schema:
#   auth_token       — Valkey AUTH string (required when TLS is enabled)
#   primary_endpoint — write endpoint (configuration endpoint in cluster mode)
#   reader_endpoint  — read-only round-robin across replicas (cluster mode disabled only)
#   port             — always 6379
#   tls              — "true" (in-transit encryption always on)

resource "aws_secretsmanager_secret_version" "valkey_connection" {
  secret_id = module.secrets.secret_id

  secret_string = jsonencode({
    auth_token       = module.secrets.auth_token
    primary_endpoint = module.valkey_cluster.primary_endpoint
    reader_endpoint  = module.valkey_cluster.reader_endpoint
    port             = tostring(module.valkey_cluster.port)
    tls              = "true"
  })
}
