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
}

run "single_node_overrides" {
  command = plan

  module {
    source = "./regional"
  }

  variables {
    anti_affinity_enabled = false
    namespace             = "openbao"
    replicas              = 1
    service_annotations   = { "cloud.google.com/neg" = "{\"ingress\": true}" }
    service_type          = "NodePort"
  }

  assert {
    condition     = yamldecode(local.helm_values).server.ha.replicas == 1 && yamldecode(local.helm_values).server.affinity == ""
    error_message = "Single-node fixtures must be able to disable anti-affinity and reduce replicas."
  }

  assert {
    condition     = yamldecode(local.helm_values).server.service.type == "NodePort" && yamldecode(local.helm_values).server.service.annotations["cloud.google.com/neg"] == "{\"ingress\": true}"
    error_message = "Consumers must be able to set the Service type and annotations for GKE ingress."
  }
}
