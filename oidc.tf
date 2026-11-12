# The OIDC provider for IRSA is now managed by
# the terraform-aws-modules/eks/aws module (enable_irsa = true) in eks.tf.
#
# Useful module outputs for other files:
#   module.eks.oidc_provider_arn  → the full ARN of the OIDC provider
#   module.eks.oidc_provider      → the issuer URL without "https://"
