locals {
  oidc_provider = trimprefix(var.oidc_provider_url, "https://")
}

resource "aws_iam_role" "controller" {
  name = "${var.cluster_name}-external-secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_policy" "read_database_secret" {
  name        = "${var.cluster_name}-external-secrets-pms-database"
  description = "Read only the PMS database connection secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue"
      ]
      Resource = var.secret_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "read_database_secret" {
  role       = aws_iam_role.controller.name
  policy_arn = aws_iam_policy.read_database_secret.arn
}
