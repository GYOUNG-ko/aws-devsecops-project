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
  identifier         = "<REDACTED_HCL_VALUE>"
  database_name      = "<REDACTED_HCL_VALUE>"
  master_username    = "<REDACTED_HCL_VALUE>"
  instance_class     = "<REDACTED_HCL_VALUE>"
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  vpc_id             = dependency.vpc.outputs.vpc_id
  secret_name        = "<REDACTED_HCL_VALUE>"
  multi_az           = false
  tags               = local.env.locals.tags
}
