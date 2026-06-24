output "secret_arns" {
  description = "Map of logical key → secret ARN."
  value       = { for k, s in aws_secretsmanager_secret.this : k => s.arn }
}

output "secret_ids" {
  description = "Map of logical key → secret ID (ARN)."
  value       = { for k, s in aws_secretsmanager_secret.this : k => s.id }
}

output "secret_names" {
  description = "Map of logical key → full secret name."
  value       = { for k, s in aws_secretsmanager_secret.this : k => s.name }
}

output "rotation_enabled" {
  description = "Map of logical key → whether Lambda rotation is configured."
  value       = { for k, v in var.secrets : k => v.rotation != null }
}

output "kms_key_ids" {
  description = "Map of logical key → the KMS key ID encrypting each secret (null = AWS-managed key)."
  value       = { for k, s in aws_secretsmanager_secret.this : k => s.kms_key_id }
}
