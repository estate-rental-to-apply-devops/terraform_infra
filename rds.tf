# ==========================================
# AWS RDS MySQL Database Configuration
# ==========================================

# 1. DB Subnet Group (Placing RDS across your private subnets)
resource "aws_db_subnet_group" "main" {
  name        = "gitops-estate-db-subnet-group"
  description = "DB subnet group for GitOps estate RDS MySQL"
  subnet_ids  = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  tags = {
    Name = "gitops-estate-db-subnet-group"
  }
}

# 2. Security Group for RDS (Allows incoming MySQL traffic ONLY from EKS Worker Nodes)
resource "aws_security_group" "rds" {
  name        = "gitops-estate-rds-sg"
  description = "Security group for RDS MySQL allowing inbound from EKS nodes only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.node.id]
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

# 3. AWS Secrets Manager for Master Password (Best Practice)
resource "random_password" "db_password" {
  length  = 16
  special = false # Avoid special characters that might break JDBC connection strings if unescaped
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "gitops-estate-mysql-credentials"
  recovery_window_in_days = 0 # Allows immediate deletion during terraform destroy
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "gitops_admin"
    password = random_password.db_password.result
    engine   = "mysql"
    host     = aws_db_instance.mysql.address
    port     = 3306
    database = "userdb" # Default/initial connection target
  })
}

# 4. RDS MySQL Instance
resource "aws_db_instance" "mysql" {
  identifier                  = "gitops-estate-mysql"
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = "db.t3.micro"
  allocated_storage           = 20
  max_allocated_storage       = 50 # Enables Storage Autoscaling up to 50GB
  storage_type                = "gp2"
  
  # Initial Databases requested
  db_name                     = "userdb" # Note: MySQL creates the first one; propertydb can be created via migration or init scripts

  username                    = "gitops_admin"
  password                    = random_password.db_password.result

  db_subnet_group_name        = aws_db_subnet_group.main.name
  vpc_security_group_ids      = [aws_security_group.rds.id]
  publicly_accessible        = false
  multi_az                    = false
  skip_final_snapshot         = true
  deletion_protection         = false
  backup_retention_period     = 0

  tags = {
    Name = "gitops-estate-mysql"
  }
}