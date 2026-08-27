include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../terraform/modules/irsa"
}

# EKS State에서 OIDC 정보 가져오기
dependency "eks" {
  config_path = "../eks"
}

inputs = {
  # EKS에서 생성한 OIDC Provider
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  oidc_provider_url = dependency.eks.outputs.cluster_oidc_issuer_url

  # IRSA를 적용할 Kubernetes Identity
  namespace            = "aws-test"
  service_account_name = "s3-reader"

  # IRSA 권한 테스트용 S3 Bucket 이름
  test_bucket_name = "irsa-test-123456789012-ap-northeast-2-an"
}
