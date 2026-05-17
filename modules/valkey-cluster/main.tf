# ── Security Group ────────────────────────────────────────────────────────────
# Placed in the data VPC. Allows inbound 6379 from EKS cluster VPC CIDRs.
# Blue VPC is always allowed; green CIDR is added during blue/green upgrade.

resource "aws_security_group" "valkey" {
  name        = "${var.name_prefix}-valkey-sg"
  description = "Valkey — allow inbound 6379 from EKS cluster VPC CIDRs"
  vpc_id      = var.data_vpc_id

  ingress {
    description = "Valkey from EKS clusters (blue + optional green)"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── Subnet Group ──────────────────────────────────────────────────────────────
# Data VPC subnets, one per AZ (sliced by az_count in root locals).

resource "aws_elasticache_subnet_group" "valkey" {
  name        = "${var.name_prefix}-valkey"
  description = "Data VPC subnets for Valkey — one per AZ"
  subnet_ids  = var.subnet_ids
}

# ── Parameter Group ───────────────────────────────────────────────────────────
# valkey7 family. Lazy freeing enabled to reduce latency spikes under memory
# pressure (eviction + expiry operations deferred to background threads).

resource "aws_elasticache_parameter_group" "valkey" {
  name        = "${var.name_prefix}-valkey-pg"
  description = "Valkey 7.x parameter group for ${var.name_prefix}"
  family      = "valkey7"

  parameter {
    name  = "lazyfree-lazy-eviction"
    value = "yes"
  }

  parameter {
    name  = "lazyfree-lazy-expire"
    value = "yes"
  }

  parameter {
    name  = "lazyfree-lazy-server-del"
    value = "yes"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── ElastiCache Valkey Replication Group ──────────────────────────────────────
# Topology is driven by num_shards:
#   num_shards = 1  → cluster mode DISABLED: 1 primary + replicas_per_shard replicas
#   num_shards > 1  → cluster mode ENABLED : N shards × (1 primary + replicas_per_shard replicas)
#
# Kong rate-limiting-advanced plugin uses Valkey as a distributed counter backend.
# When cluster mode is enabled, Kong must be configured with a cluster-aware client
# (CLUSTER_NODES environment variable or Kong's redis_cluster strategy).

resource "aws_elasticache_replication_group" "valkey" {
  replication_group_id = "${var.name_prefix}-valkey"
  description          = "${var.name_prefix} Valkey — ${var.num_shards} shard(s), cluster mode ${var.cluster_mode_enabled ? "enabled" : "disabled"}"

  engine         = "valkey"
  engine_version = var.engine_version
  node_type      = var.node_type

  # Sharding — controls cluster mode
  num_node_groups         = var.num_shards
  replicas_per_node_group = var.replicas_per_shard

  # Failover and multi-AZ
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  # Encryption — both at-rest and in-transit always on
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = true

  # AUTH — required when transit_encryption_enabled = true
  auth_token = var.auth_token

  # Network placement
  subnet_group_name  = aws_elasticache_subnet_group.valkey.name
  security_group_ids = [aws_security_group.valkey.id]

  # Parameter group
  parameter_group_name = aws_elasticache_parameter_group.valkey.name

  # Snapshots
  snapshot_retention_limit = var.snapshot_retention_days
  snapshot_window          = var.snapshot_window

  # Maintenance
  maintenance_window = var.maintenance_window

  apply_immediately = var.apply_immediately

  lifecycle {
    # Allow AWS to manage minor engine version patches without Terraform drift.
    ignore_changes = [engine_version]
  }
}
