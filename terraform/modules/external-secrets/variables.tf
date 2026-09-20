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

variable "secret_arn" {
  description = "Only this Secrets Manager secret may be read"
  type        = string
}

variable "namespace" {
  description = "External Secrets namespace"
  type        = string
  default     = "external-secrets"
}

variable "service_account_name" {
  description = "External Secrets controller ServiceAccount"
  type        = string
  default     = "external-secrets"
}

variable "tags" {
  type    = map(string)
  default = {}
}
