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
  oidc_provider_arn        = dependency.eks.outputs.oidc_provider_arn
  oidc_provider_url        = dependency.eks.outputs.cluster_oidc_issuer_url
  pms_bucket_name          = dependency.storage.outputs.bucket_name
  pms_object_prefix        = local.env.locals.pms_patch_object_prefix
  pms_namespace            = "<REDACTED_HCL_VALUE>"
  pms_service_account_name = "<REDACTED_HCL_VALUE>"
  role_name                = "<REDACTED_HCL_VALUE>"
  policy_name              = "<REDACTED_HCL_VALUE>"
  tags                     = local.env.locals.tags
}
