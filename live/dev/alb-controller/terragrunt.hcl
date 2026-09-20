locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../terraform/modules/alb-controller"
}

dependency "eks" {
  config_path = "../eks"
}

inputs = {
  tags                 = local.env.locals.tags
  cluster_name         = dependency.eks.outputs.eks_cluster_name
  oidc_provider_arn    = dependency.eks.outputs.oidc_provider_arn
  oidc_provider_url    = dependency.eks.outputs.cluster_oidc_issuer_url
  namespace            = "kube-system"
  service_account_name = "aws-load-balancer-controller"
}
