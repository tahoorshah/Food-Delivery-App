output "rds_endpoint" { value = aws_db_instance.fda.endpoint }
output "secret_name"  { value = aws_secretsmanager_secret.db.name }
# password NOT output - stays in Secrets Manager only
