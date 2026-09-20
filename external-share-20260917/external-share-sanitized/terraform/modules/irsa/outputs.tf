# Kubernetes ServiceAccount에 연결할 IAM Role ARN
output "irsa_role_arn" {
  description = "IAM Role ARN used by the IRSA ServiceAccount"
  value       = aws_iam_role.s3_reader.arn
}

# 테스트 대상으로 사용하는 기존 S3 Bucket
output "test_bucket_name" {
  description = "Existing S3 bucket used for IRSA test"
  value       = var.test_bucket_name
}

