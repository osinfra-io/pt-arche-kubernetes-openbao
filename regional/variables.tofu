# Input Variables
# https://opentofu.org/docs/language/values/variables

variable "anti_affinity_enabled" {
  description = "Require OpenBao server pods to schedule on different nodes; disable only for single-node fixtures"
  type        = bool
  default     = true
}

variable "chart_repository" {
  description = "Helm repository containing the OpenBao chart"
  type        = string
  default     = "https://openbao.github.io/openbao-helm"
}

variable "cpu_limits" {
  description = "CPU limit for each OpenBao server pod"
  type        = string
  default     = "250m"
}

variable "cpu_requests" {
  description = "CPU request for each OpenBao server pod"
  type        = string
  default     = "250m"
}

variable "labels" {
  description = "Labels applied to OpenBao server pods"
  type        = map(string)
  default     = {}
}

variable "memory_limits" {
  description = "Memory limit for each OpenBao server pod"
  type        = string
  default     = "256Mi"
}

variable "memory_requests" {
  description = "Memory request for each OpenBao server pod"
  type        = string
  default     = "256Mi"
}

variable "namespace" {
  description = "Kubernetes namespace for OpenBao"
  type        = string
}

variable "openbao_version" {
  description = "OpenBao Helm chart version"
  type        = string
  default     = "0.27.0"
}

variable "raft_configuration" {
  description = "OpenBao HCL configuration for the Raft storage stanza"
  type        = string
  default     = ""
}

variable "replicas" {
  description = "Number of OpenBao Raft server replicas"
  type        = number
  default     = 3
}

variable "server_annotations" {
  description = "Additional annotations applied to OpenBao server pods"
  type        = map(string)
  default     = {}
}

variable "server_config_annotation" {
  description = "Roll OpenBao server pods when the rendered configuration changes"
  type        = bool
  default     = true
}

variable "server_extra_environment_vars" {
  description = "Additional environment variables for OpenBao server pods"
  type        = map(string)
  default     = {}
}

variable "server_extra_volumes" {
  description = "Additional volumes mounted by OpenBao server pods"
  type = list(object({
    name = string
    type = string
  }))
  default = []
}

variable "server_service_account_annotations" {
  description = "Annotations applied to the OpenBao server Kubernetes service account"
  type        = map(string)
  default     = {}
}

variable "server_service_account_name" {
  description = "Name of the Kubernetes service account used by OpenBao server pods"
  type        = string
  default     = "openbao"
}

variable "server_update_strategy_type" {
  description = "Update strategy used for the OpenBao server StatefulSet"
  type        = string
  default     = "RollingUpdate"
}

variable "service_annotations" {
  description = "Annotations applied to the OpenBao Service, such as GKE backend configuration"
  type        = map(string)
  default     = {}
}

variable "service_type" {
  description = "Kubernetes Service type for OpenBao; GKE Ingress requires NodePort"
  type        = string
  default     = "ClusterIP"
}

variable "tls_disable" {
  description = "Disable TLS for OpenBao listeners"
  type        = bool
  default     = true
}
