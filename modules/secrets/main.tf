# ── Auth Token ────────────────────────────────────────────────────────────────
# 64-char alphanumeric token — no special characters.
# ElastiCache auth tokens must be printable ASCII (0x21–0x7E) excluding spaces,
# double-quotes, and forward-slashes. Random alphanumeric avoids edge cases.

resource "random_password" "auth_token" {
  length  = 64
  special = false
  # Produces [A-Za-z0-9] only — safe for all Valkey client libraries.
}

# ── Secrets Manager Secret ────────────────────────────────────────────────────
# Shell secret created here; the full connection bundle is written by the root
# module (aws_secretsmanager_secret_version) after the cluster endpoint is known.

resource "aws_secretsmanager_secret" "valkey" {
  name                    = "${var.name_prefix}/valkey/connection"
  description             = "Valkey connection bundle for ${var.name_prefix} — auth_token, endpoints, port, tls flag"
  recovery_window_in_days = var.secret_recovery_window_days
}
