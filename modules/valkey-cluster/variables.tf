variable "name_prefix" {
  type        = string
  description = "Resource name prefix (from root locals.name_prefix)"
}

variable "data_vpc_id" {
  type        = string
  description = "Data VPC ID — security group is placed here"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Data VPC subnet IDs (pre-sliced to az_count by root locals)"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed inbound on port 6379 (blue VPC + optional green VPC)"
}

variable "engine_version" {
  type    = string
  default = "7.2"
}

variable "node_type" {
  type    = string
  default = "cache.r7g.large"
}

variable "num_shards" {
  type    = number
  default = 1
}

variable "replicas_per_shard" {
  type    = number
  default = 1
}

variable "cluster_mode_enabled" {
  type        = bool
  default     = false
  description = "Derived from num_shards > 1 in root locals. Used for the replication group description."
}

variable "automatic_failover_enabled" {
  type        = bool
  default     = true
  description = "Derived from replicas_per_shard >= 1 in root locals. Required when cluster mode is enabled."
}

variable "multi_az_enabled" {
  type    = bool
  default = false
}

variable "auth_token" {
  type        = string
  sensitive   = true
  description = "Valkey AUTH token (from secrets module random_password output)"
}

variable "at_rest_encryption_enabled" {
  type    = bool
  default = true
}

variable "snapshot_retention_days" {
  type    = number
  default = 1
}

variable "snapshot_window" {
  type    = string
  default = "03:00-04:00"
}

variable "maintenance_window" {
  type    = string
  default = "mon:04:00-mon:05:00"
}

variable "apply_immediately" {
  type    = bool
  default = false
}
