# ==========================================
# IRSA for RDS Secrets Manager Access
# ==========================================

# 1. IAM Policy allowing read access to the MySQL database secret
resource "aws_iam_policy" "rds_secret_accessor" {
  name        = "GitOpsEstateRDSSecretAccessor"
  description = "Allows reading the MySQL credentials secret from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.db_credentials.arn
      }
    ]
  })
}

# 2. Extract clean OIDC issuer (reusing your existing pattern from irsa_alb.tf)
locals {
  oidc_issuer_clean_rds = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}

# 3. IAM Role with OIDC Trust Relationship for Kubernetes Service Account
resource "aws_iam_role" "rds_secret_accessor" {
  name = "gitops-estate-rds-secret-accessor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_issuer_clean_rds}:aud" = "sts.amazonaws.com"
            # This binds the role specifically to a future Kubernetes service account in your app namespace
            "${local.oidc_issuer_clean_rds}:sub" = "system:serviceaccount:default:gitops-app-sa"
          }
        }
      }
    ]
  })
}

# 4. Attach the Secrets Manager policy to the IRSA role
resource "aws_iam_role_policy_attachment" "rds_secret_accessor" {
  role       = aws_iam_role.rds_secret_accessor.name
  policy_arn = aws_iam_policy.rds_secret_accessor.arn
}

# ==========================================
# Output for Kubernetes Manifests
# ==========================================
output "rds_secret_accessor_role_arn" {
  description = "IAM Role ARN for your Kubernetes Service Account to fetch DB credentials"
  value       = aws_iam_role.rds_secret_accessor.arn
}