# Helm Release
# https://search.opentofu.org/provider/hashicorp/helm/latest/docs/resources/release

resource "helm_release" "openbao" {
  chart      = "openbao"
  name       = "openbao"
  namespace  = var.namespace
  repository = var.chart_repository

  values = [
    local.helm_values
  ]

  version = var.openbao_version
}
