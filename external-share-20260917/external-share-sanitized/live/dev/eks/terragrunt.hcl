locals {
  env = read_terragrunt_config(find_in_parent_folders("<REDACTED_HCL_VALUE>"))
}

include "<REDACTED_HCL_VALUE>" {
  path = find_in_parent_folders("<REDACTED_HCL_VALUE>")
}

# 재사용 가능한 EKS Terraform Module 지정
terraform {
  source = "<REDACTED_HCL_VALUE>"
}

# VPC State의 output을 읽어 EKS에 전달
dependency "<REDACTED_HCL_VALUE>" {
  config_path = "<REDACTED_HCL_VALUE>"
}

inputs = {
  tags            = local.env.locals.tags
  cluster_name    = local.env.locals.cluster_name
  cluster_version = "<REDACTED_HCL_VALUE>"

  # outputs에서 값 가져옴
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids

  node_instance_types = ["<REDACTED_HCL_VALUE>"]

  node_min_size     = 1
  node_max_size     = 2
  node_desired_size = 2
}
