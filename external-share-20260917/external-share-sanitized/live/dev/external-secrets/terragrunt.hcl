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
  tags                 = local.env.locals.tags
  cluster_name         = dependency.eks.outputs.eks_cluster_name
  oidc_provider_arn    = dependency.eks.outputs.oidc_provider_arn
  oidc_provider_url    = dependency.eks.outputs.cluster_oidc_issuer_url
  secret_arn           = dependency.rds.outputs.database_secret_arn
  namespace            = "<REDACTED_HCL_VALUE>"
  service_account_name = "<REDACTED_HCL_VALUE>"
}
