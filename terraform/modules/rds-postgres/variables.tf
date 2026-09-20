variable "identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "database_name" {
  description = "Initial PostgreSQL database"
  type        = string
}

variable "master_username" {
  description = "Initial database administrator username"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "secret_name" {
  description = "Stable Secrets Manager name consumed by External Secrets"
  type        = string
}

variable "multi_az" {
  description = "Whether to enable RDS Multi-AZ"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to RDS resources"
  type        = map(string)
  default     = {}
}
