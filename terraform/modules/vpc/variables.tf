variable "name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "tags" {
  description = "Common tags applied to all VPC resources"
  type        = map(string)
  default     = {}
}

# 실습 시 NAT Gateway 생성 여부
# true => NAT Gateway 생성
# false => NAT Gateway 삭제/미생성
variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateway"
  type        = bool
  default     = false
}
