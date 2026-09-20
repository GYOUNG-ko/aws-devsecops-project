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

dependency "<REDACTED_HCL_VALUE>" {
  config_path = "<REDACTED_HCL_VALUE>"
}

inputs = {
  oidc_provider_arn  = dependency.github_oidc.outputs.oidc_provider_arn
  role_name          = "<REDACTED_HCL_VALUE>"
  repository_owner   = "<REDACTED_HCL_VALUE>"
  repository_name    = "<REDACTED_HCL_VALUE>"
  branch             = "<REDACTED_HCL_VALUE>"
  ecr_repository_arn = dependency.ecr.outputs.repository_arn
  tags               = local.env.locals.tags
}
