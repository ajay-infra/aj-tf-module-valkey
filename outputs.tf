output "primary_endpoint" {
  description = <<-EOT
    Valkey primary endpoint for write operations.
    Cluster mode disabled : primary_endpoint_address (single shard)
    Cluster mode enabled  : configuration_endpoint_address (cluster-aware clients required)
  EOT
  value       = module.valkey_cluster.primary_endpoint
}

output "reader_endpoint" {
  description = "Valkey reader endpoint — round-robin across replicas. Available in cluster mode disabled only."
  value       = module.valkey_cluster.reader_endpoint
}

output "port" {
  description = "Valkey port (always 6379)"
  value       = module.valkey_cluster.port
}

output "security_group_id" {
  description = "Valkey security group ID — used to add targeted SG rules from EKS node groups if needed"
  value       = module.valkey_cluster.security_group_id
}

output "secret_arn" {
  description = <<-EOT
    Secrets Manager ARN for the Valkey connection bundle.
    Contains: auth_token, primary_endpoint, reader_endpoint, port, tls.
    Consumed by ESO ExternalSecret in k8s-manifests.
  EOT
  value       = module.secrets.secret_arn
}

output "replication_group_id" {
  description = "ElastiCache replication group ID — used for CloudWatch metrics and tagging"
  value       = module.valkey_cluster.replication_group_id
}

output "cluster_mode_enabled" {
  description = "True when num_shards > 1 (cluster mode). Affects client configuration — cluster-aware client required."
  value       = local.cluster_mode_enabled
}

output "active_az_count" {
  description = "Number of AZs this cluster is spread across (controlled by az_count)"
  value       = var.az_count
}

output "active_data_subnets" {
  description = "Data subnet IDs in use — sliced to az_count from data_subnet_ids"
  value       = local.active_data_subnets
}
