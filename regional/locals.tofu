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

  raft_configuration = merge(
    { enabled = true },
    var.raft_configuration == "" ? {} : { config = var.raft_configuration }
  )

  server_annotations = merge(
    {
      "ad.datadoghq.com/openbao.logs" = jsonencode([
        {
          service = "openbao"
          source  = "vault"
        }
      ])
    },
    var.server_annotations
  )

  helm_values = yamlencode({
    global = {
      tlsDisable = var.tls_disable
    }

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

      annotations = local.server_annotations

      auditStorage = {
        enabled = true
      }

      configAnnotation = var.server_config_annotation

      extraEnvironmentVars = var.server_extra_environment_vars

      extraLabels = merge(var.labels, {
        "tags.datadoghq.com/env"     = module.core_helpers.environment
        "tags.datadoghq.com/service" = "openbao"
        "tags.datadoghq.com/version" = var.openbao_version
      })

      extraVolumes = var.server_extra_volumes

      ha = {
        enabled  = true
        replicas = var.replicas
        raft     = local.raft_configuration
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

      serviceAccount = {
        annotations = var.server_service_account_annotations
        name        = var.server_service_account_name
      }

      updateStrategyType = var.server_update_strategy_type
    }

    ui = {
      enabled = true
    }
  })

  service_name = "openbao"
}
