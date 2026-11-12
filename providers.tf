provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Project   = "GitOpsEstateRental"
      ManagedBy = "Terraform"
    }
  }
}

# Required by the terraform-aws-modules/eks module for OIDC certificate thumbprint
provider "tls" {}