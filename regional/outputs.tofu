# Output Values
# https://opentofu.org/docs/language/values/outputs

output "namespace" {
  description = "Namespace containing OpenBao"
  value       = var.namespace
}

output "service_name" {
  description = "Name of the OpenBao Service"
  value       = local.service_name
}

output "service_port" {
  description = "Port exposed by the OpenBao Service"
  value       = 8200
}
