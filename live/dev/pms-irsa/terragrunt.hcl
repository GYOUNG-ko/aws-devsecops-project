locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}
include "root" {
  path = find_in_parent_folders("root.hcl")
}
terraform {
  source = "../../../terraform/modules/pms-irsa"
}
dependency "eks" {
  config_path = "../eks"
}
dependency "storage" {
  config_path = "../pms-storage"
}
inputs = {
  oidc_provider_arn        = dependency.eks.outputs.oidc_provider_arn
  oidc_provider_url        = dependency.eks.outputs.cluster_oidc_issuer_url
  pms_bucket_name          = dependency.storage.outputs.bucket_name
  pms_object_prefix        = local.env.locals.pms_patch_object_prefix
  pms_namespace            = "default"
  pms_service_account_name = "pms-backend"
  role_name                = "${local.env.locals.cluster_name}-pms-backend-s3-reader"
  policy_name              = "${local.env.locals.cluster_name}-pms-backend-s3-read"
  tags                     = local.env.locals.tags
}
