# OIDC URL에서 https:// 제거
# IAM Trust Policy의 Condition key에 사용
locals {
  oidc_provider = replace(
    var.oidc_provider_url,
    "https://",
    ""
  )

}

# IRSA IAM Role
resource "aws_iam_role" "s3_reader" {
  name = var.role_name

  # EKS ServiceAccount가 Web Identity를 통해
  # 이 IAM Role을 Assume할 수 있도록 신뢰 관계 구성
  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        # 신뢰 대상
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # 발급 대상이 AWS STS인지 확인
            "${local.oidc_provider}:aud" = "sts.amazonaws.com"

            # 지정한 ServiceAccount만 Role 사용 가능
            "${local.oidc_provider}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# S3 ReadOnly 최소 권한 Policy
# Role 획득 후 역할 정의
resource "aws_iam_policy" "s3_read_only" {
  name        = var.policy_name
  description = "Allow IRSA test pod to read only the test S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        # Bucket 내부 목록 조회
        Sid    = "ListBucket"
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = "arn:aws:s3:::${var.test_bucket_name}"
      },
      {
        # Bucket 내부 Object 조회
        Sid    = "GetObject"
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = "arn:aws:s3:::${var.test_bucket_name}/*"
      }
    ]
  })
}

# IAM Role ↔ Permission Policy 연결
resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.s3_reader.name
  policy_arn = aws_iam_policy.s3_read_only.arn
}

