locals {
  name_prefix = "${lower(replace(var.cluster_name, " ", "-"))}-${var.environment}"

  # Data VPC subnets sliced to az_count.
  # Subnets must be ordered by AZ (standard aj-tf-module-vpc output).
  # min() guards against callers passing fewer subnets than az_count.
  active_data_subnets = slice(var.data_subnet_ids, 0, min(var.az_count, length(var.data_subnet_ids)))

  # Cluster mode is enabled when more than one shard is requested.
  # This drives num_node_groups in the replication group.
  cluster_mode_enabled = var.num_shards > 1

  # Automatic failover is enabled whenever at least one replica exists.
  # Required when cluster mode is enabled.
  automatic_failover_enabled = var.replicas_per_shard >= 1

  # Allowed source CIDRs on port 6379.
  # Always includes the blue VPC; green is added dynamically when the
  # green cluster is live (during a blue/green upgrade window).
  allowed_cidr_blocks = concat(
    [var.blue_vpc_cidr],
    var.green_enabled ? [var.green_vpc_cidr] : []
  )

  full_tags = merge(var.common_tags, {
    Environment = var.environment
    Team        = var.team
    CostCenter  = var.cost_center
    ClusterName = var.cluster_name
    AZCount     = tostring(var.az_count)
  }, var.tags)
}
