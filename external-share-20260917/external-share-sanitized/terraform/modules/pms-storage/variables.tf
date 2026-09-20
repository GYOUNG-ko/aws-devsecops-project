variable "project_name" {
  description = "Project name used for resource tags"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "bucket_name" {
  description = "Globally unique private PMS patch bucket name"
  type        = string
}
