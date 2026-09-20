locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../terraform/modules/irsa"
}

# EKS State에서 OIDC 정보 가져오기
dependency "eks" {
  config_path = "../eks"
}

inputs = {
  role_name   = "${local.env.locals.cluster_name}-s3-reader"
  policy_name = "${local.env.locals.cluster_name}-irsa-s3-read-only"
  tags        = local.env.locals.tags
  # EKS에서 생성한 OIDC Provider
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  oidc_provider_url = dependency.eks.outputs.cluster_oidc_issuer_url

  # IRSA를 적용할 Kubernetes Identity
  namespace            = "aws-test"
  service_account_name = "s3-reader"

  # IRSA 권한 테스트용 S3 Bucket 이름
  test_bucket_name = "irsa-test-123456789012-ap-northeast-2-an"

}
