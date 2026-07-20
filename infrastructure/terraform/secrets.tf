# Password is generated and stored in Secrets Manager -- never in a .tf file or state-visible plain var.
resource "random_password" "db" {
  length  = 20
  special = false # avoid characters Postgres/URL-encoding can trip on
}

resource "aws_secretsmanager_secret" "db" {
  name = "${var.project_name}/rds/credentials"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
  })
}