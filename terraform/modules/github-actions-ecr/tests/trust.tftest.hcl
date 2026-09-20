mock_provider "aws" {
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/test-policy"
    }
  }
}
variables {
  oidc_provider_arn  = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  role_name          = "test-ci"
  repository_owner   = "example"
  repository_name    = "application"
  branch             = "release"
  ecr_repository_arn = "arn:aws:ecr:ap-northeast-2:123456789012:repository/application"
}
run "external_provider_and_exact_branch" {
  command = plan
  assert {
    condition     = jsondecode(aws_iam_role.github_actions.assume_role_policy).Statement[0].Principal.Federated == var.oidc_provider_arn && jsondecode(aws_iam_role.github_actions.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == "repo:example/application:ref:refs/heads/release"
    error_message = "CI must use the shared identity and restrict trust to the chosen repository and branch."
  }
  assert {
    condition     = jsondecode(aws_iam_policy.ecr_push.policy).Statement[1].Resource == var.ecr_repository_arn
    error_message = "Push permission must be restricted to the application repository."
  }
}
