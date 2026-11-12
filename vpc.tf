# ==========================================
# VPC — terraform-aws-modules/vpc/aws
# Replaces: raw vpc.tf resources + routes.tf
# ==========================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "gitops-estate-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.20.0/24"]

  # Single NAT Gateway — cost-saving choice for a learning project
  enable_nat_gateway = true
  single_nat_gateway = true

  # Tags required by the AWS Load Balancer Controller to discover subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/gitops-estate-cluster" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/gitops-estate-cluster" = "shared"
  }

  tags = {
    Name = "gitops-estate-vpc"
  }
}