# RDS PostgreSQL (Multi-AZ for HA). Scaffold. Use Secrets Manager for creds.
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_db_instance" "this" {
  identifier              = "${var.name}-postgres"
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  db_name                 = var.db_name
  username                = var.username
  password                = var.password # TODO: source from Secrets Manager
  multi_az                = var.multi_az
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = var.security_group_ids
  backup_retention_period = var.backup_retention_days
  storage_encrypted       = true
  skip_final_snapshot     = var.skip_final_snapshot
  tags                    = var.tags
}
