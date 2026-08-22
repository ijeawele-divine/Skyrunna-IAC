output "endpoint" {
  description = "RDS endpoint hostname"
  value       = aws_db_instance.main.endpoint
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Database master username"
  value       = aws_db_instance.main.username
}

output "port" {
  description = "Database port"
  value       = aws_db_instance.main.port
}

output "instance_id" {
  description = "RDS instance identifier"
  value = aws_db_instance.main.identifier
}