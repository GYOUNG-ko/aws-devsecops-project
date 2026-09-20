variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS IAM OIDC provider ARN"
  type        = string
}

variable "oidc_provider_url" {
  description = "EKS OIDC issuer URL"
  type        = string
}

variable "namespace" {
  description = "Controller namespace"
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Controller Kubernetes ServiceAccount name"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "tags" {
  type    = map(string)
  default = {}
}
