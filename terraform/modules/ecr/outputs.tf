output "repository_url" {
  description = "ECR repository URL used by the Kubernetes Deployment"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ECR repository ARN used by the GitHub Actions push policy"
  value       = aws_ecr_repository.this.arn
}
