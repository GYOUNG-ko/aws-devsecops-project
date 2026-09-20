locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../terraform/modules/pms-storage"
}

inputs = {
  project_name = "aws-devsecops-project"
  environment  = local.env.locals.environment
  bucket_name  = local.env.locals.pms_patch_bucket_name
}
