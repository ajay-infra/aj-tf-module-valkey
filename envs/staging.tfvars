# envs/staging.tfvars — Valkey config for staging environment
# Used with: -var-file=envs/staging.tfvars (plus common.tfvars from aj-infra-release)

environment  = "staging"
cluster_name = "ai-search-staging"
aws_region   = "us-east-1"

# Network — filled in by aj-infra-release pipeline from vpc module outputs
# data_vpc_id     = "<from vpc output>"
# data_subnet_ids = ["<from vpc output>"]

blue_vpc_cidr  = "10.110.0.0/16"
green_enabled  = false
green_vpc_cidr = "10.111.0.0/16"

az_count = 2

# Engine
engine_version = "7.2"
node_type      = "cache.r7g.large" # Same as dev — staging mirrors dev topology

# Topology: cluster mode disabled, single shard, 1 replica
num_shards         = 1
replicas_per_shard = 1
multi_az_enabled   = false

# Snapshots: moderate retention
snapshot_retention_days     = 3
snapshot_window             = "03:00-04:00"
maintenance_window          = "mon:04:00-mon:05:00"
apply_immediately           = false # staging: respect maintenance window
secret_recovery_window_days = 7

team        = "infra-core"
cost_center = "infra-2026-q1"
tags = {
  Owner = "ajay"
  Env   = "staging"
}
