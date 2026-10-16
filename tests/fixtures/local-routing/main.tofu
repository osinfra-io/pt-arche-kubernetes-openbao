module "local_routing" {
  source = "../../../regional/local"

  namespace = "openbao"
}

output "route_manifest" {
  value = module.local_routing.route_manifest
}
