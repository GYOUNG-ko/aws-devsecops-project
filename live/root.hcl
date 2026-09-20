terragrunt_version_constraint = "= 1.1.4"
terraform_version_constraint  = "= 1.12.6"

locals {
  account    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region     = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  aws_region = local.region.locals.aws_region
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  allowed_account_ids = ["${local.account.locals.account_id}"]
}
EOF
}

remote_state {
  backend                         = "s3"
  disable_dependency_optimization = true

  config = {
    bucket                = local.account.locals.state_bucket
    key                   = "${replace(path_relative_to_include(), "\\", "/")}/terraform.tfstate"
    region                = local.aws_region
    encrypt               = true
    use_lockfile          = true
    disable_bucket_update = true
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Guard runs before backend initialization as well as direct plan/apply commands.
terraform {
  before_hook "state_ownership_preflight" {
    commands = ["init", "plan", "apply", "destroy", "import"]
    execute = [
      "python3", "${get_parent_terragrunt_dir("root")}/../devops/scripts/state_preflight.py",
      "--bucket", local.account.locals.state_bucket,
      "--key", "${replace(path_relative_to_include(), "\\", "/")}/terraform.tfstate",
      "--region", local.aws_region,
      "--account", local.account.locals.account_id,
    ]
  }
}
