locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../terraform/modules/github-actions-ecr"
}

dependency "ecr" {
  config_path = "../ecr"
}

dependency "github_oidc" {
  config_path = "../../shared/github-oidc"
}

inputs = {
  oidc_provider_arn  = dependency.github_oidc.outputs.oidc_provider_arn
  role_name          = "github-actions-pms-ecr"
  repository_owner   = "GYOUNG-ko"
  repository_name    = "aws-devsecops-project"
  branch             = "main"
  ecr_repository_arn = dependency.ecr.outputs.repository_arn
  tags               = local.env.locals.tags
}
