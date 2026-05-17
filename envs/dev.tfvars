# envs/dev.tfvars — Valkey config for dev environment
# Used with: -var-file=envs/dev.tfvars (plus common.tfvars from aj-infra-release)

environment  = "dev"
cluster_name = "ai-search-dev"
aws_region   = "us-east-1"

# Network — filled in by aj-infra-release pipeline from vpc module outputs
# data_vpc_id     = "<from vpc output>"
# data_subnet_ids = ["<from vpc output>"]

blue_vpc_cidr  = "10.100.0.0/16"
green_enabled  = false
green_vpc_cidr = "10.101.0.0/16"

az_count = 2

# Engine
engine_version = "7.2"
node_type      = "cache.r7g.large" # ARM Graviton — cost-efficient for dev

# Topology: cluster mode disabled, single shard, 1 replica
num_shards         = 1
replicas_per_shard = 1
multi_az_enabled   = false

# Snapshots: minimal retention to reduce storage cost
snapshot_retention_days     = 1
snapshot_window             = "03:00-04:00"
maintenance_window          = "mon:04:00-mon:05:00"
apply_immediately           = true
secret_recovery_window_days = 0 # 0 = immediate delete (avoids name collision on re-create)

team        = "infra-core"
cost_center = "infra-2026-q1"
tags = {
  Owner = "ajay"
  Env   = "dev"
}
