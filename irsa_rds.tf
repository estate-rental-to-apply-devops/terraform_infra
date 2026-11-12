# ==========================================
# IRSA for RDS Secrets Manager Access
# ==========================================

# IAM Policy allowing read access to the MySQL database secret
resource "aws_iam_policy" "rds_secret_accessor" {
  name        = "GitOpsEstateRDSSecretAccessor"
  description = "Allows reading the MySQL credentials secret from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.db_credentials.arn
      }
    ]
  })
}

# IAM Role with OIDC Trust Relationship — bound to the app's Kubernetes ServiceAccount
resource "aws_iam_role" "rds_secret_accessor" {
  name = "gitops-estate-rds-secret-accessor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
            # Binds this role specifically to the app's ServiceAccount in its namespace
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:gitops-app-ns:gitops-app-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_secret_accessor" {
  role       = aws_iam_role.rds_secret_accessor.name
  policy_arn = aws_iam_policy.rds_secret_accessor.arn
}

output "rds_secret_accessor_role_arn" {
  description = "IAM Role ARN for your Kubernetes Service Account to fetch DB credentials"
  value       = aws_iam_role.rds_secret_accessor.arn
}