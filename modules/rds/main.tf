locals {
  final_snapshot_identifier = coalesce(var.final_snapshot_identifier, "${var.name_prefix}-final")
}

resource "aws_kms_key" "db" {
  description             = "KMS key for ${var.name_prefix} RDS"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }

  tags = var.tags
}

resource "aws_kms_alias" "db" {
  name          = "alias/${var.name_prefix}-rds"
  target_key_id = aws_kms_key.db.key_id
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnets"
  })
}

resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-db"
  description = "Database security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-sg"
  })
}

resource "aws_security_group_rule" "db_ingress" {
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = var.app_security_group_id
  security_group_id        = aws_security_group.db.id
  description              = "DB access from application security group"
}

resource "aws_db_instance" "this" {
  identifier = "${var.name_prefix}-db"

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.db_username
  port     = var.db_port

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.db.arn

  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.db.arn

  multi_az               = var.multi_az
  publicly_accessible    = var.publicly_accessible
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  backup_retention_period         = var.backup_retention_period
  backup_window                   = var.backup_window
  maintenance_window              = var.maintenance_window
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = local.final_snapshot_identifier

  apply_immediately = var.apply_immediately

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }

  tags = var.tags
}
