output "auth_token" {
  description = "Generated Valkey AUTH token (64-char alphanumeric, no special chars)"
  value       = random_password.auth_token.result
  sensitive   = true
}

output "secret_arn" {
  description = "Secrets Manager secret ARN — used by ESO SecretStore policy"
  value       = aws_secretsmanager_secret.valkey.arn
}

output "secret_id" {
  description = "Secrets Manager secret ID (path name) — used by aws_secretsmanager_secret_version in root"
  value       = aws_secretsmanager_secret.valkey.id
}
