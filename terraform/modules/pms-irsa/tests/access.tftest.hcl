mock_provider "aws" {
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/test-policy"
    }
  }
}
variables {
  oidc_provider_arn        = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.ap-northeast-2.amazonaws.com/id/TEST"
  oidc_provider_url        = "https://oidc.eks.ap-northeast-2.amazonaws.com/id/TEST"
  pms_bucket_name          = "example-patches"
  pms_namespace            = "pms"
  pms_service_account_name = "backend"
  role_name                = "test-pms-reader"
  policy_name              = "test-pms-read"
}
run "only_selected_service_account_and_patch_prefix" {
  command = plan
  assert {
    condition     = jsondecode(aws_iam_role.pms_backend.assume_role_policy).Statement[0].Condition.StringEquals["oidc.eks.ap-northeast-2.amazonaws.com/id/TEST:sub"] == "system:serviceaccount:pms:backend"
    error_message = "The PMS role must trust only its selected ServiceAccount."
  }
  assert {
    condition     = jsondecode(aws_iam_policy.pms_patch_read.policy).Statement[0].Condition.StringLike["s3:prefix"] == ["patches/*"] && jsondecode(aws_iam_policy.pms_patch_read.policy).Statement[1].Resource == "arn:aws:s3:::example-patches/patches/*"
    error_message = "PMS must not read outside its patch prefix."
  }
  assert {
    condition     = toset(flatten([for s in jsondecode(aws_iam_policy.pms_patch_read.policy).Statement : s.Action])) == toset(["s3:ListBucket", "s3:GetObject"])
    error_message = "PMS must not acquire write or unrelated S3 permissions."
  }
}
run "reject_outside_patch_prefix" {
  command = plan
  variables {
    pms_object_prefix = "private/"
  }
  expect_failures = [var.pms_object_prefix]
}
