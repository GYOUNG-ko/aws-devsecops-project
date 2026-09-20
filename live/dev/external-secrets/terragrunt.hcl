locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../terraform/modules/external-secrets"
}

dependency "eks" {
  config_path = "../eks"
}

dependency "rds" {
  config_path = "../rds"
}

inputs = {
  tags                 = local.env.locals.tags
  cluster_name         = dependency.eks.outputs.eks_cluster_name
  oidc_provider_arn    = dependency.eks.outputs.oidc_provider_arn
  oidc_provider_url    = dependency.eks.outputs.cluster_oidc_issuer_url
  secret_arn           = dependency.rds.outputs.database_secret_arn
  namespace            = "external-secrets"
  service_account_name = "external-secrets"
}
