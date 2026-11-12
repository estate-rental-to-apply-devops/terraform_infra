# ==========================================
# EKS Cluster — terraform-aws-modules/eks/aws
# Replaces: raw eks.tf + iam.tf + oidc.tf + addons.tf
# ==========================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "gitops-estate-cluster"
  cluster_version = var.k8s_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Allow API server access from both inside the VPC and your local machine
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Grant the Terraform caller IAM identity cluster-admin access via EKS Access Entry
  enable_cluster_creator_admin_permissions = true

  # IRSA — registers the OIDC provider with AWS IAM (replaces oidc.tf)
  enable_irsa = true

  # EKS Add-ons (replaces addons.tf)
  cluster_addons = {
    vpc-cni    = { most_recent = true }
    kube-proxy = { most_recent = true }
    coredns    = { most_recent = true }
  }

  # Managed Node Group (replaces eks.tf node group + iam.tf node role)
  eks_managed_node_groups = {
    main = {
      name           = "gitops-nodes"
      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }

  tags = {
    Name = "gitops-estate-cluster"
  }
}
