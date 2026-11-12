# ==========================================
# IRSA for AWS Load Balancer Controller
# Using: terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks
#
# The module manages the IAM policy internally — no iam_policy.json needed.
# It stays in sync with AWS automatically on every module version bump.
# ==========================================

module "alb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "gitops-estate-aws-load-balancer-controller"

  # The module maintains this policy — no local JSON file needed
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

output "alb_controller_iam_role_arn" {
  description = "IAM Role ARN for the AWS Load Balancer Controller Service Account"
  value       = module.alb_controller_irsa.iam_role_arn
}
