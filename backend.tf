terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # Required by the terraform-aws-modules/eks module for OIDC certificate thumbprint
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    # Required by rds.tf for random_password
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket       = "gitops-estate-terraform-state"
    key          = "vpc/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
    encrypt      = true
  }
}