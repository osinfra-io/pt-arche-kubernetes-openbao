# Test
# https://opentofu.org/docs/cli/commands/test

mock_provider "helm" {}

run "default_regional" {
  command = apply

  module {
    source = "./tests/fixtures/default/regional"
  }

  assert {
    condition     = output.service_name == "openbao" && output.service_port == 8200
    error_message = "The OpenBao Service name and port must remain stable for consumers."
  }

  assert {
    condition     = output.namespace == "openbao"
    error_message = "The module must expose the explicitly supplied namespace."
  }
}

run "high_availability_defaults" {
  command = plan

  module {
    source = "./regional"
  }

  override_module {
    target = module.core_helpers
    outputs = {
      env         = "prod"
      environment = "production"
      region      = "us-east1"
      zone        = "b"
    }
  }

  variables {
    namespace = "caller-owned-openbao"
  }

  assert {
    condition     = helm_release.openbao.namespace == "caller-owned-openbao"
    error_message = "The Helm release must use the namespace supplied by the caller."
  }

  assert {
    condition     = yamldecode(local.helm_values).server.ha.replicas == 3 && yamldecode(local.helm_values).server.ha.raft.enabled
    error_message = "OpenBao must default to a three-replica Raft cluster."
  }

  assert {
    condition     = strcontains(yamldecode(local.helm_values).server.affinity, "requiredDuringSchedulingIgnoredDuringExecution")
    error_message = "OpenBao replicas must default to required pod anti-affinity."
  }

  assert {
    condition     = yamldecode(local.helm_values).server.service.type == "ClusterIP"
    error_message = "OpenBao must default to an internal ClusterIP Service."
  }

  assert {
    condition     = yamldecode(local.helm_values).server.updateStrategyType == "OnDelete" && !yamldecode(local.helm_values).server.configAnnotation
    error_message = "Manual-unseal deployments must not enable automatic rollouts or configuration checksums by default."
  }

  assert {
    condition = alltrue([
      for component, service in { server = "openbao", injector = "openbao-injector" } :
      yamldecode(helm_release.openbao.values[0])[component].extraLabels == {
        "tags.datadoghq.com/env"     = "production"
        "tags.datadoghq.com/service" = service
        "tags.datadoghq.com/version" = var.openbao_version
      }
    ])
    error_message = "OpenBao server and injector must carry full unified tags with their distinct lowercase service identities."
  }

  assert {
    condition = alltrue([
      for container, component in { openbao = "server", sidecar-injector = "injector" } :
      jsondecode(yamldecode(helm_release.openbao.values[0])[component].annotations["ad.datadoghq.com/${container}.logs"])[0].source == "vault" &&
      jsondecode(yamldecode(helm_release.openbao.values[0])[component].annotations["ad.datadoghq.com/${container}.logs"])[0].service ==
      yamldecode(helm_release.openbao.values[0])[component].extraLabels["tags.datadoghq.com/service"]
    ])
    error_message = "OpenBao log autodiscovery must target each real container, preserve the native Vault source, and agree with its service labels."
  }
}

run "single_node_overrides" {
  command = plan

  module {
    source = "./regional"
  }

  variables {
    anti_affinity_enabled = false

    labels = {
      "app.kubernetes.io/instance" = "openbao"
      "app.kubernetes.io/name"     = "openbao"
      component                    = "server"
      team                         = "platform"
    }

    namespace           = "openbao"
    replicas            = 1
    service_annotations = { "cloud.google.com/neg" = "{\"ingress\": true}" }
    service_type        = "NodePort"
  }

  assert {
    condition     = yamldecode(local.helm_values).server.ha.replicas == 1 && yamldecode(local.helm_values).server.affinity == ""
    error_message = "Single-node fixtures must be able to disable anti-affinity and reduce replicas."
  }

  assert {
    condition     = yamldecode(local.helm_values).server.service.type == "NodePort" && yamldecode(local.helm_values).server.service.annotations["cloud.google.com/neg"] == "{\"ingress\": true}"
    error_message = "Consumers must be able to set the Service type and annotations for GKE ingress."
  }

  assert {
    condition = alltrue([
      for key, value in var.labels :
      yamldecode(helm_release.openbao.values[0]).server.extraLabels[key] == value
      ]) && alltrue([
      for key in keys(var.labels) :
      !contains(keys(yamldecode(helm_release.openbao.values[0]).injector.extraLabels), key)
    ])
    error_message = "Caller labels must remain server-only so they cannot overwrite the injector's pod selector labels."
  }
}

run "custom_server_configuration" {
  command = plan

  module {
    source = "./regional"
  }

  override_module {
    target = module.core_helpers
    outputs = {
      env         = "prod"
      environment = "production"
      region      = "us-east1"
      zone        = "b"
    }
  }

  variables {
    namespace = "openbao"

    raft_configuration = <<-EOT
      ui = true

      listener "tcp" {
        address = "[::]:8200"
        cluster_address = "[::]:8201"
        tls_cert_file = "/openbao/userconfig/openbao-tls/tls.crt"
        tls_key_file = "/openbao/userconfig/openbao-tls/tls.key"
      }

      seal "gcpckms" {
        crypto_key = "openbao"
        key_ring = "openbao"
        project = "pt-example"
        region = "us"
      }

      storage "raft" {
        path = "/openbao/data"
      }

      service_registration "kubernetes" {}
    EOT

    server_annotations = {
      "ad.datadoghq.com/openbao.checks" = "{\"vault\":{\"instances\":[{\"api_url\":\"https://%%host%%:8200/v1\"}]}}"
    }

    server_config_annotation = true

    server_extra_environment_vars = {
      BAO_CACERT = "/openbao/userconfig/openbao-tls/ca.crt"
    }

    server_extra_volumes = [
      {
        name = "openbao-tls"
        type = "secret"
      }
    ]

    server_service_account_annotations = {
      "iam.gke.io/gcp-service-account" = "openbao@example.iam.gserviceaccount.com"
    }

    server_service_account_name = "openbao"
    server_update_strategy_type = "RollingUpdate"
    service_annotations         = { "cloud.google.com/neg" = "{\"ingress\": true}" }
    service_type                = "NodePort"
    tls_disable                 = false
  }

  assert {
    condition = (
      yamldecode(local.helm_values).global.tlsDisable == false &&
      yamldecode(local.helm_values).server.ha.raft.config == var.raft_configuration
    )
    error_message = "The module must support TLS-enabled OpenBao listeners and caller-supplied Raft configuration."
  }

  assert {
    condition = (
      yamldecode(local.helm_values).server.extraEnvironmentVars.BAO_CACERT == var.server_extra_environment_vars.BAO_CACERT &&
      yamldecode(local.helm_values).server.extraVolumes[0] == var.server_extra_volumes[0] &&
      yamldecode(local.helm_values).server.configAnnotation &&
      yamldecode(local.helm_values).server.updateStrategyType == "RollingUpdate"
    )
    error_message = "The module must support TLS certificate mounts, environment variables, and configuration-triggered rollouts."
  }

  assert {
    condition = (
      yamldecode(local.helm_values).server.serviceAccount.name == var.server_service_account_name &&
      yamldecode(local.helm_values).server.serviceAccount.annotations["iam.gke.io/gcp-service-account"] == "openbao@example.iam.gserviceaccount.com" &&
      yamldecode(local.helm_values).server.annotations["ad.datadoghq.com/openbao.checks"] == var.server_annotations["ad.datadoghq.com/openbao.checks"] &&
      yamldecode(local.helm_values).server.service.type == "NodePort"
    )
    error_message = "The module must expose workload identity, Datadog, and GKE service configuration."
  }
}

run "tls_requires_custom_server_configuration" {
  command = plan

  module {
    source = "./regional"
  }

  variables {
    namespace   = "openbao"
    tls_disable = false
  }

  expect_failures = [var.tls_disable]
}

run "tls_rejects_blank_server_configuration" {
  command = plan

  module {
    source = "./regional"
  }

  variables {
    namespace          = "openbao"
    raft_configuration = " \n "
    tls_disable        = false
  }

  expect_failures = [var.tls_disable]
}
