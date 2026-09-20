terragrunt_version_constraint = "<REDACTED_HCL_VALUE>"
terraform_version_constraint  = "<REDACTED_HCL_VALUE>"

locals {
  account    = read_terragrunt_config(find_in_parent_folders("<REDACTED_HCL_VALUE>"))
  region     = read_terragrunt_config(find_in_parent_folders("<REDACTED_HCL_VALUE>"))
  aws_region = local.region.locals.aws_region
}

generate "<REDACTED_HCL_VALUE>" {
  path      = "<REDACTED_HCL_VALUE>"
  if_exists = "<REDACTED_HCL_VALUE>"

  contents = <<EOF
provider "<REDACTED_HCL_VALUE>" {
  region = "<REDACTED_HCL_VALUE>"
  allowed_account_ids = ["<REDACTED_HCL_VALUE>"]
}
EOF
}

remote_state {
  backend                         = "<REDACTED_HCL_VALUE>"
  disable_dependency_optimization = true

  config = {
    bucket                = local.account.locals.state_bucket
    key                   = "<REDACTED_HCL_VALUE>"\\"<REDACTED_HCL_VALUE>"/"<REDACTED_HCL_VALUE>"
    region                = local.aws_region
    encrypt               = true
    use_lockfile          = true
    disable_bucket_update = true
  }

  generate = {
    path      = "<REDACTED_HCL_VALUE>"
    if_exists = "<REDACTED_HCL_VALUE>"
  }
}

# Guard runs before backend initialization as well as direct plan/apply commands.
terraform {
  before_hook "<REDACTED_HCL_VALUE>" {
    commands = ["<REDACTED_HCL_VALUE>", "<REDACTED_HCL_VALUE>", "<REDACTED_HCL_VALUE>", "<REDACTED_HCL_VALUE>", "<REDACTED_HCL_VALUE>"]
    execute = [
      "<REDACTED_HCL_VALUE>", "<REDACTED_HCL_VALUE>"root"<REDACTED_HCL_VALUE>",
      "<REDACTED_HCL_VALUE>", local.account.locals.state_bucket,
      "<REDACTED_HCL_VALUE>", "<REDACTED_HCL_VALUE>"\\"<REDACTED_HCL_VALUE>"/"<REDACTED_HCL_VALUE>",
      "<REDACTED_HCL_VALUE>", local.aws_region,
      "<REDACTED_HCL_VALUE>", local.account.locals.account_id,
    ]
  }
}
