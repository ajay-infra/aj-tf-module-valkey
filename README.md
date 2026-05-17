# aj-tf-module-valkey

Terraform module for **ElastiCache Valkey** — the BSD-licensed open-source fork of Redis (API-compatible). Deployed into the data VPC and shared across blue and green EKS clusters.

## Why Valkey

AWS made Valkey the primary ElastiCache focus after the Redis BSL license change (March 2024). Valkey is API-compatible with Redis — all existing Redis clients work without changes.

## Architecture

```
                    Data VPC (10.x.102.0/16)
                    ┌─────────────────────────────────────┐
                    │  ElastiCache Subnet Group           │
                    │  ┌──────────┐   ┌──────────┐        │
                    │  │  AZ-a    │   │  AZ-b    │        │
                    │  │ Primary  │   │ Replica  │        │
                    │  └──────────┘   └──────────┘        │
                    │                                     │
                    │  SG: allow 6379 from:               │
                    │    blue VPC CIDR  (always)          │
                    │    green VPC CIDR (when upgrading)  │
                    └─────────────────────────────────────┘
                              ▲           ▲
                    Blue EKS  │           │  Green EKS
                    (shared — not duplicated per color)
```

## Module Structure

```
aj-tf-module-valkey/
├── modules/
│   ├── secrets/          # random auth_token + Secrets Manager secret
│   └── valkey-cluster/   # security group, subnet group, parameter group, replication group
├── envs/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod-blue.tfvars
├── example.tfvars        # CI / local plan reference
├── locals.tf
├── main.tf
├── outputs.tf
├── providers.tf
└── variables.tf
```

## Usage

```hcl
module "valkey" {
  source = "git::https://github.com/ajay-infra/aj-tf-module-valkey.git?ref=v1.0.0"

  cluster_name = "ai-search-prod"
  environment  = "prod"

  data_vpc_id     = module.vpc.data_vpc_id
  data_subnet_ids = module.vpc.data_subnet_ids

  blue_vpc_cidr  = "10.120.0.0/16"
  green_enabled  = false
  green_vpc_cidr = "10.121.0.0/16"

  az_count = 3

  engine_version     = "7.2"
  node_type          = "cache.r7g.xlarge"
  num_shards         = 3   # cluster mode enabled (prod)
  replicas_per_shard = 1
  multi_az_enabled   = true

  snapshot_retention_days     = 7
  apply_immediately           = false
  secret_recovery_window_days = 7
}
```

## Topology Modes

| `num_shards` | Mode | Use case |
|---|---|---|
| 1 | Cluster mode **disabled** | dev / staging — simpler client config |
| 3+ | Cluster mode **enabled** | prod — horizontal sharding, higher throughput |

When `num_shards > 1`, Kong's `rate-limiting-advanced` plugin must be configured with `redis_cluster` strategy.

## Inputs

| Variable | Default | Description |
|---|---|---|
| `cluster_name` | — | Logical name used in resource naming |
| `environment` | `dev` | Environment tag |
| `data_vpc_id` | — | Data VPC ID from vpc module |
| `data_subnet_ids` | — | Data subnet IDs ordered by AZ |
| `blue_vpc_cidr` | — | Blue EKS VPC CIDR — allowed on 6379 |
| `green_enabled` | `false` | Add green VPC CIDR to SG |
| `green_vpc_cidr` | `""` | Green EKS VPC CIDR |
| `az_count` | `2` | Number of AZs (2/3/4) |
| `engine_version` | `7.2` | Valkey engine version |
| `node_type` | `cache.r7g.large` | ElastiCache node type |
| `num_shards` | `1` | Shards (1 = cluster mode disabled) |
| `replicas_per_shard` | `1` | Replicas per shard (enables automatic failover) |
| `multi_az_enabled` | `false` | Spread across AZs |
| `snapshot_retention_days` | `1` | Daily snapshot retention |
| `apply_immediately` | `false` | Apply changes immediately |
| `secret_recovery_window_days` | `7` | Secret deletion protection |

## Outputs

| Output | Description |
|---|---|
| `primary_endpoint` | Write endpoint (configuration endpoint in cluster mode) |
| `reader_endpoint` | Read endpoint (cluster mode disabled only) |
| `port` | Always `6379` |
| `security_group_id` | Valkey SG ID |
| `secret_arn` | Secrets Manager ARN — connection bundle for ESO |
| `replication_group_id` | ElastiCache replication group ID |
| `cluster_mode_enabled` | `true` when `num_shards > 1` |

## Requirements

| Tool | Version |
|---|---|
| Terraform | `= 1.7.5` |
| AWS provider | `= 5.100.0` |
| random provider | `= 3.6.3` |
