include "root" {
  path = find_in_parent_folders("root.hcl")
}

# 재사용 가능한 EKS Terraform Module 지정
terraform {
  source = "../../../terraform/modules/eks"
}

# VPC State의 output을 읽어 EKS에 전달
dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  cluster_name    = "dev-eks"
  cluster_version = "1.35"

  # outputs에서 값 가져옴
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids

  node_instance_types = ["t3.small"]

  node_min_size     = 1
  node_max_size     = 2
  node_desired_size = 2
}
