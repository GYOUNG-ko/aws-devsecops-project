locals {
  oidc_provider     = replace(var.oidc_provider_url, "https://", "")
  pms_object_prefix = trimsuffix(var.pms_object_prefix, "/")
}

# PMS Backend 전용 IRSA Role. 기존 aws-cli 테스트 Role과 분리한다.
resource "aws_iam_role" "pms_backend" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider}:aud" = "sts.amazonaws.com"
            "${local.oidc_provider}:sub" = "system:serviceaccount:${var.pms_namespace}:${var.pms_service_account_name}"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, { Purpose = "pms-backend-s3-read" })
}

# patches/ 하위만 목록 조회 및 Object 읽기가 가능한 최소 권한 Policy
resource "aws_iam_policy" "pms_patch_read" {
  name        = var.policy_name
  description = "Allow PMS Backend to list and read only the configured patch prefix"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListPatchPrefix"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.pms_bucket_name}"
        Condition = {
          StringLike = {
            "s3:prefix" = ["${local.pms_object_prefix}/*"]
          }
        }
      },
      {
        Sid      = "GetPatchObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${var.pms_bucket_name}/${local.pms_object_prefix}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pms_patch_read" {
  role       = aws_iam_role.pms_backend.name
  policy_arn = aws_iam_policy.pms_patch_read.arn
}

