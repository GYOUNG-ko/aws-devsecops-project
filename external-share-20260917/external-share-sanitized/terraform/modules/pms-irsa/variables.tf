variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}

variable "pms_bucket_name" {
  description = "Private PMS patch bucket supplied by the storage unit."
  type        = string
  nullable    = false
}

variable "pms_object_prefix" {
  description = "PMS patch object prefix available to the Backend Role"
  type        = string
  default     = "patches/"

  validation {
    condition     = startswith(var.pms_object_prefix, "patches/") && endswith(var.pms_object_prefix, "/")
    error_message = "pms_object_prefix must start with patches/ and end with /."
  }
}

variable "pms_namespace" {
  description = "Kubernetes namespace for the PMS Backend ServiceAccount"
  type        = string
  default     = "default"
}

variable "pms_service_account_name" {
  description = "Kubernetes ServiceAccount name for the PMS Backend"
  type        = string
  default     = "pms-backend"
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
