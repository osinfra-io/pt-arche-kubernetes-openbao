# Local Values
# https://opentofu.org/docs/language/values/locals

locals {
  # The chart renders `server.affinity` as a template, so it is a string rather than a map.
  affinity = var.anti_affinity_enabled ? local.anti_affinity : ""

  anti_affinity = <<-EOT
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app.kubernetes.io/name: openbao
              app.kubernetes.io/instance: openbao
              component: server
          topologyKey: kubernetes.io/hostname
  EOT

  helm_values = yamlencode({
    injector = {
      annotations = {
        "ad.datadoghq.com/sidecar-injector.logs" = jsonencode([
          {
            service = "openbao-injector"
            source  = "vault"
          }
        ])
      }

      enabled = true

      extraLabels = {
        "tags.datadoghq.com/env"     = module.core_helpers.environment
        "tags.datadoghq.com/service" = "openbao-injector"
        "tags.datadoghq.com/version" = var.openbao_version
      }
    }

    server = {
      affinity = local.affinity

      annotations = {
        "ad.datadoghq.com/openbao.logs" = jsonencode([
          {
            service = "openbao"
            source  = "vault"
          }
        ])
      }

      auditStorage = {
        enabled = true
      }

      extraLabels = merge(var.labels, {
        "tags.datadoghq.com/env"     = module.core_helpers.environment
        "tags.datadoghq.com/service" = "openbao"
        "tags.datadoghq.com/version" = var.openbao_version
      })

      ha = {
        enabled  = true
        replicas = var.replicas

        raft = {
          enabled = true
        }
      }

      resources = {
        limits = {
          cpu    = var.cpu_limits
          memory = var.memory_limits
        }
        requests = {
          cpu    = var.cpu_requests
          memory = var.memory_requests
        }
      }

      service = {
        annotations = var.service_annotations
        type        = var.service_type
      }
    }

    ui = {
      enabled = true
    }
  })

  service_name = "openbao"
}
