output "primary_endpoint" {
  description = <<-EOT
    Write endpoint for Valkey.
    Cluster mode disabled : primary_endpoint_address (direct to primary shard)
    Cluster mode enabled  : configuration_endpoint_address (cluster-aware client required)
  EOT
  value = var.num_shards > 1 ? (
    aws_elasticache_replication_group.valkey.configuration_endpoint_address
    ) : (
    aws_elasticache_replication_group.valkey.primary_endpoint_address
  )
}

output "reader_endpoint" {
  description = <<-EOT
    Read-only round-robin endpoint across all replica nodes.
    Available in cluster mode disabled only. In cluster mode, use primary_endpoint
    with a cluster-aware client that handles read routing internally.
  EOT
  value = aws_elasticache_replication_group.valkey.reader_endpoint_address
}

output "port" {
  description = "Valkey port (always 6379)"
  value       = 6379
}

output "security_group_id" {
  description = "Valkey security group ID — can be referenced in EKS node group SG rules"
  value       = aws_security_group.valkey.id
}

output "replication_group_id" {
  description = "ElastiCache replication group ID"
  value       = aws_elasticache_replication_group.valkey.id
}
