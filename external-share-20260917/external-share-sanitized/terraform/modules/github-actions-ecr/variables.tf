variable "role_name" {
  description = "IAM role name assumed by GitHub Actions"
  type        = string
}

variable "repository_owner" {
  description = "GitHub organization or user"
  type        = string
}

variable "repository_name" {
  description = "GitHub repository name"
  type        = string
}

variable "branch" {
  description = "Only this branch may assume the deployment role"
  type        = string
  default     = "main"
}

variable "ecr_repository_arn" {
  description = "Only this ECR repository may receive images"
  type        = string
}

variable "tags" {
  description = "Tags applied to IAM resources"
  type        = map(string)
  default     = {}
}

variable "oidc_provider_arn" {
  description = "Account-owned GitHub OIDC provider ARN"
  type        = string
}
