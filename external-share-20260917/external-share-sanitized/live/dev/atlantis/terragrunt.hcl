locals {
  env = read_terragrunt_config(find_in_parent_folders("<REDACTED_HCL_VALUE>"))
}

include "<REDACTED_HCL_VALUE>" {
  path = find_in_parent_folders("<REDACTED_HCL_VALUE>")
}

terraform {
  source = "<REDACTED_HCL_VALUE>"
}

dependency "<REDACTED_HCL_VALUE>" {
  config_path = "<REDACTED_HCL_VALUE>"
}

inputs = {
  project_name      = "<REDACTED_HCL_VALUE>"
  environment       = local.env.locals.environment
  vpc_id            = dependency.vpc.outputs.vpc_id
  private_subnet_id = dependency.vpc.outputs.private_subnet_ids[0]
  instance_type     = "<REDACTED_HCL_VALUE>"
  root_volume_size  = 20
}

