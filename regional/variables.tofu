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

variable "replicas" {
  description = "Number of OpenBao Raft server replicas"
  type        = number
  default     = 3
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
