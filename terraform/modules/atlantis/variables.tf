variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Atlantis will be deployed"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for Atlantis EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Atlantis"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 20
}