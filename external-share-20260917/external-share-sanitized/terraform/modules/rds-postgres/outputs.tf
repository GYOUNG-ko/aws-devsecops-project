output "database_address" {
  description = "RDS PostgreSQL hostname"
  value       = aws_db_instance.this.address
}

output "database_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.this.port
}

output "database_secret_arn" {
  description = "Secrets Manager ARN read by External Secrets"
  value       = aws_secretsmanager_secret.database.arn
}

output "database_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.database.id
}
