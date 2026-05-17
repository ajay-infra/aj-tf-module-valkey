# ── Core ─────────────────────────────────────────────────────────────────────

variable "cluster_name" {
  type        = string
  description = "Logical cluster name used in resource naming (e.g. 'ai-search-dev')"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

# ── Network (from vpc module outputs) ────────────────────────────────────────

variable "data_vpc_id" {
  type        = string
  description = "Data VPC ID — Valkey lives here, isolated from EKS workload VPCs"
}

variable "data_subnet_ids" {
  type        = list(string)
  description = <<-EOT
    Data VPC subnet IDs ordered by AZ (standard aj-tf-module-vpc output: data_subnet_ids).
    Pass all available; az_count controls how many are used.
  EOT
}

variable "blue_vpc_cidr" {
  type        = string
  description = "Blue EKS cluster VPC CIDR — allowed inbound on port 6379"
}

variable "green_enabled" {
  type        = bool
  default     = false
  description = "Set true when the green EKS cluster VPC exists. Adds green_vpc_cidr to the SG."
}

variable "green_vpc_cidr" {
  type        = string
  default     = ""
  description = "Green EKS cluster VPC CIDR — only used when green_enabled = true"
}

# ── AZ Count ──────────────────────────────────────────────────────────────────

variable "az_count" {
  type        = number
  description = <<-EOT
    Number of Availability Zones to place subnet group nodes in.
      2 = dev/staging   (cost-optimised)
      3 = prod default  (standard HA)
      4 = regulated     (strict SLA)
    Must be <= length(data_subnet_ids). Subnets must be ordered by AZ.
  EOT
  default     = 2
  validation {
    condition     = contains([2, 3, 4], var.az_count)
    error_message = "az_count must be 2, 3, or 4."
  }
}

# ── Engine ────────────────────────────────────────────────────────────────────

variable "engine_version" {
  type        = string
  default     = "7.2"
  description = <<-EOT
    Valkey engine version (e.g. '7.2').
    Valkey is the BSD-licensed open-source fork of Redis (API-compatible).
    AWS made Valkey the primary ElastiCache focus after Redis BSL change (March 2024).
    Check supported versions: https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/supported-engine-versions.html
  EOT
}

variable "node_type" {
  type        = string
  default     = "cache.r7g.large"
  description = <<-EOT
    ElastiCache node type. Graviton ARM recommended for cost/performance.
    dev/staging : cache.r7g.large  (~$0.166/hr)
    prod        : cache.r7g.xlarge (~$0.333/hr)
    Kong rate-limiting plugin uses Valkey as distributed counter backend — size accordingly.
  EOT
}

# ── Cluster Topology ──────────────────────────────────────────────────────────

variable "num_shards" {
  type        = number
  description = <<-EOT
    Number of shards (node groups).
      1  = cluster mode DISABLED — single shard, one primary + replicas_per_shard replicas (dev/staging)
      3+ = cluster mode ENABLED  — horizontal sharding, data partitioned across shards (prod)
    Kong rate-limiting-advanced plugin requires a cluster-mode-aware client when num_shards > 1.
  EOT
  default     = 1
  validation {
    condition     = var.num_shards >= 1
    error_message = "num_shards must be >= 1."
  }
}

variable "replicas_per_shard" {
  type        = number
  description = <<-EOT
    Number of read replicas per shard.
      0 = no replicas, no automatic failover (not recommended for prod)
      1 = one replica per shard, automatic failover enabled (dev/prod default)
    Automatic failover is enabled automatically when replicas_per_shard >= 1.
  EOT
  default     = 1
  validation {
    condition     = var.replicas_per_shard >= 0 && var.replicas_per_shard <= 5
    error_message = "replicas_per_shard must be between 0 and 5."
  }
}

variable "multi_az_enabled" {
  type        = bool
  default     = false
  description = "Spread primary and replica nodes across AZs. Requires replicas_per_shard >= 1. Enable for prod."
}

# ── Encryption ────────────────────────────────────────────────────────────────

variable "at_rest_encryption_enabled" {
  type        = bool
  default     = true
  description = "Encrypt data at rest using AWS-managed keys. Always true — included for auditability."
}

# ── Snapshots ────────────────────────────────────────────────────────────────

variable "snapshot_retention_days" {
  type        = number
  description = <<-EOT
    Daily snapshot retention in days.
      0 = snapshots disabled
      1 = dev/staging default
      7 = prod default
  EOT
  default     = 1
  validation {
    condition     = var.snapshot_retention_days >= 0 && var.snapshot_retention_days <= 35
    error_message = "snapshot_retention_days must be between 0 and 35."
  }
}

variable "snapshot_window" {
  type        = string
  default     = "03:00-04:00"
  description = "Daily snapshot window (UTC). Format: hh:mm-hh:mm. Must not overlap maintenance_window."
}

variable "maintenance_window" {
  type        = string
  default     = "mon:04:00-mon:05:00"
  description = "Weekly maintenance window (UTC). Format: ddd:hh:mm-ddd:hh:mm."
}

# ── Secrets Manager ───────────────────────────────────────────────────────────

variable "secret_recovery_window_days" {
  type        = number
  default     = 7
  description = <<-EOT
    Days before a deleted Secrets Manager secret is purged.
    Set to 0 for immediate deletion (dev only — avoids name collision when re-creating).
    Minimum 7 for staging/prod — required for recovery in case of accidental deletion.
  EOT
  validation {
    condition     = var.secret_recovery_window_days == 0 || (var.secret_recovery_window_days >= 7 && var.secret_recovery_window_days <= 30)
    error_message = "secret_recovery_window_days must be 0 (immediate) or 7-30."
  }
}

# ── Operations ────────────────────────────────────────────────────────────────

variable "apply_immediately" {
  type        = bool
  default     = false
  description = "Apply configuration changes immediately rather than waiting for the next maintenance window. Use true for dev, false for prod."
}

# ── Tags ──────────────────────────────────────────────────────────────────────

variable "team" {
  type    = string
  default = "infra-core"
}

variable "cost_center" {
  type    = string
  default = "infra-2026-q1"
}

variable "common_tags" {
  type = map(string)
  default = {
    Project    = "ai-search"
    ManagedBy  = "Terraform"
    Repository = "aj-tf-module-valkey"
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
