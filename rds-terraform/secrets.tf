resource "aws_secretsmanager_secret" "db" {
  name                    = "fda/db/credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = aws_db_instance.fda.username
    password = random_password.db.result
    dbname   = aws_db_instance.fda.db_name
    host     = aws_db_instance.fda.address
    port     = aws_db_instance.fda.port
  })
}
