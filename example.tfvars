# example.tfvars — used for terraform plan / CI validation
# Replace dummy VPC/subnet IDs with real outputs from aj-tf-module-vpc

# ── Core ──────────────────────────────────────────────────────────────────────
cluster_name = "ai-search-dev"
aws_region   = "us-east-1"
environment  = "dev"

# ── Network (from vpc module outputs) ─────────────────────────────────────────
# data_vpc_id     → vpc module output: data_vpc_id
# data_subnet_ids → vpc module output: data_subnet_ids (ordered by AZ)
data_vpc_id     = "vpc-0data1234567890abc"
data_subnet_ids = ["subnet-data111aaa", "subnet-data222bbb"]

# EKS VPC CIDRs — inbound access to Valkey on 6379
blue_vpc_cidr  = "10.100.0.0/16"
green_enabled  = false
green_vpc_cidr = "10.101.0.0/16" # Only used when green_enabled = true

# ── AZ Count ──────────────────────────────────────────────────────────────────
# 2 = dev / staging   — 2 AZs, cost-optimised
# 3 = production      — 3 AZs, standard HA
az_count = 2

# ── Engine ────────────────────────────────────────────────────────────────────
engine_version = "7.2"
node_type      = "cache.r7g.large" # ARM Graviton — dev/staging

# ── Cluster Topology ──────────────────────────────────────────────────────────
# num_shards = 1  → cluster mode DISABLED (dev/staging)
# num_shards = 3  → cluster mode ENABLED  (prod — 3-shard horizontal sharding)
num_shards         = 1
replicas_per_shard = 1  # 1 primary + 1 replica → automatic failover enabled
multi_az_enabled   = false

# ── Snapshots + Maintenance ───────────────────────────────────────────────────
snapshot_retention_days = 1     # dev: 1 day   prod: 7 days
snapshot_window         = "03:00-04:00"
maintenance_window      = "mon:04:00-mon:05:00"

# ── Operations ────────────────────────────────────────────────────────────────
apply_immediately           = true  # dev: apply now   prod: false (maintenance window)
secret_recovery_window_days = 0     # 0 = immediate delete (dev only)

# ── Tags ──────────────────────────────────────────────────────────────────────
team        = "infra-core"
cost_center = "infra-2026-q1"
tags = {
  Owner = "ajay"
}
