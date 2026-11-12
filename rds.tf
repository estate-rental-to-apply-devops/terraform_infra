# ==========================================
# AWS RDS MySQL Database Configuration
# ==========================================

# 1. DB Subnet Group — using private subnets from the VPC module
resource "aws_db_subnet_group" "main" {
  name        = "gitops-estate-db-subnet-group"
  description = "DB subnet group for GitOps estate RDS MySQL"
  subnet_ids  = module.vpc.private_subnets

  tags = {
    Name = "gitops-estate-db-subnet-group"
  }
}

# 2. AWS Secrets Manager for Master Password (Best Practice)
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
    database = "userdb"
  })
}

# 3. RDS MySQL Instance
# Security group is defined in security_groups.tf
resource "aws_db_instance" "mysql" {
  identifier            = "gitops-estate-mysql"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 50 # Enables Storage Autoscaling up to 50GB
  storage_type          = "gp2"

  db_name  = "userdb"
  username = "gitops_admin"
  password = random_password.db_password.result

  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = false
  multi_az                = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0

  tags = {
    Name = "gitops-estate-mysql"
  }
}