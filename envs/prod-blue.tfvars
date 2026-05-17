# envs/prod-blue.tfvars — Valkey config for production
# Valkey is shared across blue + green EKS clusters — no blue/green suffix here.
# green_enabled flips to true only during a live blue/green cutover window.
# Used with: -var-file=envs/prod-blue.tfvars (plus common.tfvars from aj-infra-release)

environment  = "prod"
cluster_name = "ai-search-prod"
aws_region   = "us-east-1"

# Network — filled in by aj-infra-release pipeline from vpc module outputs
# data_vpc_id     = "<from vpc output>"
# data_subnet_ids = ["<from vpc output>"]

blue_vpc_cidr  = "10.120.0.0/16"
green_enabled  = false      # flip to true when green EKS cluster is live
green_vpc_cidr = "10.121.0.0/16"

az_count = 3 # prod: 3 AZs for standard HA

# Engine
engine_version = "7.2"
node_type      = "cache.r7g.xlarge" # Scaled up for prod — Kong RL + RAG cache load

# Topology: cluster mode ENABLED — 3 shards × (1 primary + 1 replica) = 6 nodes
# Kong rate-limiting-advanced must use redis_cluster strategy for distributed counters
num_shards         = 3
replicas_per_shard = 1
multi_az_enabled   = true # primary and replica in different AZs

# Snapshots: 7-day retention for prod
snapshot_retention_days     = 7
snapshot_window             = "02:00-03:00"
maintenance_window          = "sun:03:00-sun:04:00"
apply_immediately           = false # prod: changes go through maintenance window only
secret_recovery_window_days = 7

team        = "infra-core"
cost_center = "infra-2026-q1"
tags = {
  Owner = "ajay"
  Env   = "prod"
}
