locals {
  # Keep the real AWS account ID out of Git. The sentinel keeps offline HCL
  # validation possible and causes the existing state ownership preflight to
  # fail closed before any real infrastructure command when the variable is unset.
  account_id = get_env("AWS_ACCOUNT_ID", "000000000000")

  # The real backend bucket is derived at runtime. Override TF_STATE_BUCKET only
  # when the deployed bucket does not follow this naming convention.
  state_bucket = get_env("TF_STATE_BUCKET", "aws-project-tfstate-${local.account_id}-ap-northeast-2-an")
  project      = "aws-devsecops-project"
}
