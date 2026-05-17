variable "name_prefix" {
  type        = string
  description = "Resource name prefix (from root locals.name_prefix)"
}

variable "secret_recovery_window_days" {
  type        = number
  default     = 7
  description = "Days before deleted secret is permanently purged. 0 = immediate (dev only)."
}
