include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common_tags = {
    Project     = "aws-devsecops-project"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

terraform {
  source = "../../../terraform/modules/vpc"
}

inputs = {
  name     = "dev-eks-vpc"
  vpc_cidr = "10.0.0.0/16"

  availability_zones = [
    "ap-northeast-2a",
    "ap-northeast-2c"
  ]

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_subnet_cidrs = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]

  # 실습 중 private subnet의 outbound 연결을 위해 활성화
  # 실습 종료 시 false로 변경, terragrunt apply, NAT Gateway & EIP 제거
  enable_nat_gateway = true
  #enable_nat_gateway = false

  tags = local.common_tags
}
