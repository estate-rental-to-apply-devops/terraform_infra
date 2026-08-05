# ==========================================
# IRSA for AWS Load Balancer Controller
# ==========================================


resource "aws_iam_policy" "alb_controller" {
  name        = "GitOpsEstateAWSLoadBalancerControllerPolicy"
  description = "Permissions for AWS Load Balancer Controller to manage ALBs/NLBs"
  policy      = file("${path.module}/iam_policy.json")
}


# 2. Extract OIDC provider details for the Trust Policy
locals {
  oidc_issuer_clean = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}

# 3. Create IAM Role with OIDC Trust Relationship
resource "aws_iam_role" "alb_controller" {
  name = "gitops-estate-aws-load-balancer-controller"

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
            "${local.oidc_issuer_clean}:aud" = "sts.amazonaws.com"
            "${local.oidc_issuer_clean}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

# 4. Attach Policy to Role
resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# Output the Role ARN so you can annotate your Kubernetes Service Account later
output "alb_controller_iam_role_arn" {
  description = "IAM Role ARN for the AWS Load Balancer Controller Service Account"
  value       = aws_iam_role.alb_controller.arn
}
