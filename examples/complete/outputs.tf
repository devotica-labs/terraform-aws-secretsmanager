output "secret_arns" {
  description = "Logical key → secret ARN."
  value       = module.secrets.secret_arns
}

output "secret_names" {
  description = "Logical key → full secret name."
  value       = module.secrets.secret_names
}

output "rotation_enabled" {
  description = "Logical key → whether rotation is configured."
  value       = module.secrets.rotation_enabled
}
