resource "aws_db_subnet_group" "main" {
  name       = "skyrunna-${var.env}-rds-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "skyrunna-${var.env}-rds-subnet-group"
    Environment = var.env
  }
}

resource "aws_db_instance" "main" {
  identifier        = "skyrunna-${var.env}-postgres"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = data.aws_ssm_parameter.db_password.value

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]

  skip_final_snapshot     = true
  deletion_protection     = false
  multi_az                = false
  publicly_accessible     = false
  backup_retention_period = 7

  tags = {
    Name        = "skyrunna-${var.env}-postgres"
    Environment = var.env
  }
}

data "aws_ssm_parameter" "db_password" {
  name            = "/skyrunna/${var.env}/POSTGRES_PASSWORD"
  with_decryption = true
}