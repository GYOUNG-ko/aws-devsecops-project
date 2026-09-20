# EKS에서 생성한 OIDC Provider ARN
variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  type        = string
}

variable "oidc_provider_url" {
  description = "EKS OIDC provider URL"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for IRSA"
  type        = string
  default     = "aws-test"
}

variable "service_account_name" {
  description = "Kubernetes ServiceAccount name"
  type        = string
  default     = "s3-reader"
}

variable "test_bucket_name" {
  description = "Existing S3 bucket name for IRSA permission test"
  type        = string
}


variable "role_name" {
  type = string
}

variable "policy_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
