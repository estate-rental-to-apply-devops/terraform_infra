# ==========================================
# ECR Repositories for Microservices & Frontend
# ==========================================

locals {
  services = [
    "gateway-service",
    "authorization-service",
    "property-management-service",
    "rental-agreement-service",
    "user-management-service",
    "config-service",
    "frontend-service"
  ]
}

# 1. Create ECR Repositories using a for_each loop
resource "aws_ecr_repository" "services" {
  for_each             = toset(local.services)
  name                 = "gitops-estate/${each.value}"
  image_tag_mutability = "MUTABLE" # Allows updating tags like :latest during development
  force_delete         = true

  # Best Practice: Enable security vulnerability scanning on every push
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# 2. Attach Lifecycle Policies to manage storage and cut unnecessary costs
resource "aws_ecr_lifecycle_policy" "cleanup" {
  for_each   = aws_ecr_repository.services
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last 5 tagged images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ==========================================
# Outputs for convenience when pushing manually
# ==========================================

output "ecr_repository_urls" {
  description = "The repository URLs for pushing your docker images manually"
  value       = { for k, repo in aws_ecr_repository.services : k => repo.repository_url }
}