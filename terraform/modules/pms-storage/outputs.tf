output "bucket_name" {
  description = "Private PMS patch bucket name"
  value       = aws_s3_bucket.patches.bucket
}

output "bucket_arn" {
  description = "Private PMS patch bucket ARN"
  value       = aws_s3_bucket.patches.arn
}

output "patch_prefix" {
  description = "Required logical object prefix for PMS patch objects"
  value       = "patches/"
}
