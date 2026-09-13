# Random DB password - never hardcoded, never in Git
resource "random_password" "db" {
  length  = 20
  special = true
  override_special = "!#$%&*()-_=+[]{}"
}

# Default VPC + subnets (task uses default VPC)
data "aws_vpc" "default" { default = true }
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# SG: allow Postgres only from within the VPC (no public exposure)
resource "aws_security_group" "rds" {
  name        = "fda-rds-sg"
  description = "RDS access from within VPC only"
  vpc_id      = data.aws_vpc.default.id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "fda-rds-sg" }
}

resource "aws_db_subnet_group" "rds" {
  name       = "fda-rds-subnets"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_db_instance" "fda" {
  identifier             = "fda-db"
  engine                 = "postgres"
  engine_version         = "16.4"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_encrypted      = true
  db_name                = "fooddelivery"
  username               = "fdaadmin"
  password               = random_password.db.result
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot     = true
  backup_retention_period = 1
}
