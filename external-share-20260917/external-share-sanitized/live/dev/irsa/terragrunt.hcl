locals {
  env = read_terragrunt_config(find_in_parent_folders("<REDACTED_HCL_VALUE>"))
}

include "<REDACTED_HCL_VALUE>" {
  path   = find_in_parent_folders("<REDACTED_HCL_VALUE>")
  expose = true
}

terraform {
  source = "<REDACTED_HCL_VALUE>"
}

# EKS State에서 OIDC 정보 가져오기
dependency "<REDACTED_HCL_VALUE>" {
  config_path = "<REDACTED_HCL_VALUE>"
}

inputs = {
  role_name   = "<REDACTED_HCL_VALUE>"
  policy_name = "<REDACTED_HCL_VALUE>"
  tags        = local.env.locals.tags
  # EKS에서 생성한 OIDC Provider
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  oidc_provider_url = dependency.eks.outputs.cluster_oidc_issuer_url

  # IRSA를 적용할 Kubernetes Identity
  namespace            = "<REDACTED_HCL_VALUE>"
  service_account_name = "<REDACTED_HCL_VALUE>"

  # IRSA 권한 테스트용 S3 Bucket 이름
  test_bucket_name = "<REDACTED_HCL_VALUE>"

}
