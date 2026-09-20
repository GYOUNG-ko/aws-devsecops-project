resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%&*+-.:=?^_~"
}

resource "aws_security_group" "database" {
  name_prefix = "${var.identifier}-"
  description = "PostgreSQL access from the EKS node and default Pod security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name      = "${var.identifier}-database"
    Component = "database"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "this" {
  name       = var.identifier
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name      = var.identifier
    Component = "database"
  })
}

resource "aws_db_instance" "this" {
  identifier = var.identifier

  engine         = "postgres"
  instance_class = var.instance_class
  db_name        = var.database_name
  username       = var.master_username
  password       = random_password.master.result
  port           = 5432

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period         = 7
  backup_window                   = "17:00-18:00"
  maintenance_window              = "sun:18:00-sun:19:00"
  auto_minor_version_upgrade      = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.identifier}-final"
  copy_tags_to_snapshot     = true
  apply_immediately         = false

  tags = merge(var.tags, {
    Name      = var.identifier
    Component = "database"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_secretsmanager_secret" "database" {
  name                    = var.secret_name
  description             = "PMS PostgreSQL connection settings managed by Terraform"
  recovery_window_in_days = 7

  tags = merge(var.tags, {
    Name      = var.secret_name
    Component = "database-secret"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    PMS_DATABASE_HOST     = aws_db_instance.this.address
    PMS_DATABASE_PORT     = tostring(aws_db_instance.this.port)
    PMS_DATABASE_NAME     = var.database_name
    PMS_DATABASE_USERNAME = var.master_username
    PMS_DATABASE_PASSWORD = random_password.master.result
  })
}
