# ==========================================
# Security Groups
# NOTE: The EKS module manages its own cluster and node security groups
#       automatically. Only the ALB and RDS security groups are defined here.
#
# Key module output used below:
#   module.eks.node_security_group_id  → SG attached to all EKS worker nodes
# ==========================================

# ==========================================
# 1. Application Load Balancer (ALB) Security Group
# ==========================================
resource "aws_security_group" "alb" {
  name        = "gitops-estate-alb-sg"
  description = "Security group for public ALB ingress"
  vpc_id      = module.vpc.vpc_id

  # Allow HTTP public traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  # Allow HTTPS public traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  # Restrict egress: Only allow the ALB to talk to the EKS Worker Nodes
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [module.eks.node_security_group_id]
    description     = "Allow ALB outbound traffic exclusively to EKS worker nodes"
  }

  tags = {
    Name = "gitops-estate-alb-sg"
  }
}

# ==========================================
# 2. RDS Security Group
# ==========================================
resource "aws_security_group" "rds" {
  name        = "gitops-estate-rds-sg"
  description = "Security group for RDS MySQL allowing inbound from EKS nodes only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
    description     = "Allow inbound MySQL traffic exclusively from EKS worker nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic from RDS"
  }

  tags = {
    Name = "gitops-estate-rds-sg"
  }
}