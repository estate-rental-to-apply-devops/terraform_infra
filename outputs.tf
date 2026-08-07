# ==========================================
# RDS Outputs
# ==========================================

output "rds_endpoint" {
  description = "The connection endpoint for the MySQL database"
  value       = aws_db_instance.mysql.address
}

output "rds_secret_arn" {
  description = "The AWS Secrets Manager ARN containing master username and password"
  value       = aws_secretsmanager_secret.db_credentials.arn
}