locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../terraform/modules/atlantis"
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  project_name      = "aws-devsecops"
  environment       = local.env.locals.environment
  vpc_id            = dependency.vpc.outputs.vpc_id
  private_subnet_id = dependency.vpc.outputs.private_subnet_ids[0]
  instance_type     = "t3.small"
  root_volume_size  = 20
}

