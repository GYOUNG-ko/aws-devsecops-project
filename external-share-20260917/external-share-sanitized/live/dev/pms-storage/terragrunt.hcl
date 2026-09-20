locals {
  env = read_terragrunt_config(find_in_parent_folders("<REDACTED_HCL_VALUE>"))
}

include "<REDACTED_HCL_VALUE>" {
  path   = find_in_parent_folders("<REDACTED_HCL_VALUE>")
  expose = true
}

terraform {
  source = "<REDACTED_HCL_VALUE>"
}

inputs = {
  project_name = "<REDACTED_HCL_VALUE>"
  environment  = local.env.locals.environment
  bucket_name  = local.env.locals.pms_patch_bucket_name
}
