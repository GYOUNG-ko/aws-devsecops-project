output "role_arn" {
  description = "Role ARN configured in the GitHub Actions workflow"
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN"
  value       = var.oidc_provider_arn
}
