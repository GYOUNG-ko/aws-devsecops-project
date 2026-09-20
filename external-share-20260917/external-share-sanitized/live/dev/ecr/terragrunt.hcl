locals {
  env = read_terragrunt_config(find_in_parent_folders("<REDACTED_HCL_VALUE>"))
}

include "<REDACTED_HCL_VALUE>" {
  path = find_in_parent_folders("<REDACTED_HCL_VALUE>")
}

terraform {
  source = "<REDACTED_HCL_VALUE>"
}

inputs = {
  repository_name = "<REDACTED_HCL_VALUE>"
  tags            = local.env.locals.tags
}
