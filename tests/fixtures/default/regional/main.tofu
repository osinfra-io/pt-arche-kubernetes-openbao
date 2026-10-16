module "openbao" {
  source = "../../../../regional"

  namespace = "openbao"
}

output "namespace" {
  value = module.openbao.namespace
}

output "service_name" {
  value = module.openbao.service_name
}

output "service_port" {
  value = module.openbao.service_port
}
