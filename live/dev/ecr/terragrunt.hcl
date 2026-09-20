locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../terraform/modules/ecr"
}

inputs = {
  repository_name = "pms-backend"
  tags            = local.env.locals.tags
}
