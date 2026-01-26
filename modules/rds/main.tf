locals {
  final_snapshot_identifier = coalesce(var.final_snapshot_identifier, "${var.name_prefix}-final")
  backup_vault_name_input   = var.backup_vault_name == null ? "" : trimspace(var.backup_vault_name)
  backup_vault_name         = length(local.backup_vault_name_input) > 0 ? var.backup_vault_name : "${var.name_prefix}-rds-backup"
  backup_plan_name          = "${var.name_prefix}-rds-backup"
}

resource "aws_kms_key" "db" {
  count = var.prevent_destroy ? 0 : 1

  description             = "KMS key for ${var.name_prefix} RDS"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_kms_key" "db_protected" {
  count = var.prevent_destroy ? 1 : 0

  description             = "KMS key for ${var.name_prefix} RDS"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

locals {
  kms_key_id  = var.prevent_destroy ? aws_kms_key.db_protected[0].key_id : aws_kms_key.db[0].key_id
  kms_key_arn = var.prevent_destroy ? aws_kms_key.db_protected[0].arn : aws_kms_key.db[0].arn
}

resource "aws_kms_alias" "db" {
  name          = "alias/${var.name_prefix}-rds"
  target_key_id = local.kms_key_id
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

resource "aws_security_group_rule" "db_ingress_additional" {
  count = length(var.additional_ingress_security_group_ids)

  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = var.additional_ingress_security_group_ids[count.index]
  security_group_id        = aws_security_group.db.id
  description              = "DB access from additional security groups"
}

resource "aws_db_instance" "this" {
  count = var.prevent_destroy ? 0 : 1

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
  kms_key_id            = local.kms_key_arn

  manage_master_user_password   = true
  master_user_secret_kms_key_id = local.kms_key_arn

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

  tags = var.tags
}

resource "aws_db_instance" "protected" {
  count = var.prevent_destroy ? 1 : 0

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
  kms_key_id            = local.kms_key_arn

  manage_master_user_password   = true
  master_user_secret_kms_key_id = local.kms_key_arn

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
    prevent_destroy = true
  }

  tags = var.tags
}

locals {
  db_instance_id      = var.prevent_destroy ? aws_db_instance.protected[0].id : aws_db_instance.this[0].id
  db_instance_arn     = var.prevent_destroy ? aws_db_instance.protected[0].arn : aws_db_instance.this[0].arn
  db_instance_address = var.prevent_destroy ? aws_db_instance.protected[0].address : aws_db_instance.this[0].address
  db_instance_port    = var.prevent_destroy ? aws_db_instance.protected[0].port : aws_db_instance.this[0].port
  backup_copy_enabled = length(trimspace(var.backup_copy_destination_vault_arn)) > 0
}

data "aws_iam_policy_document" "backup_assume" {
  count = var.enable_backup_plan ? 1 : 0

  statement {
    sid     = "AllowBackupServiceAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "backup_kms" {
  count = var.enable_backup_plan ? 1 : 0

  statement {
    sid = "AllowBackupKeyUsage"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [local.kms_key_arn]
  }
}

resource "aws_iam_role" "backup" {
  count = var.enable_backup_plan ? 1 : 0

  name               = "${var.name_prefix}-rds-backup"
  assume_role_policy = data.aws_iam_policy_document.backup_assume[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  count      = var.enable_backup_plan ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  count      = var.enable_backup_plan ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_iam_role_policy" "backup_kms" {
  count  = var.enable_backup_plan ? 1 : 0
  name   = "${var.name_prefix}-rds-backup-kms"
  role   = aws_iam_role.backup[0].id
  policy = data.aws_iam_policy_document.backup_kms[0].json
}

resource "aws_backup_vault" "rds" {
  count = var.enable_backup_plan ? 1 : 0

  name        = local.backup_vault_name
  kms_key_arn = local.kms_key_arn

  tags = var.tags
}

resource "aws_backup_plan" "rds" {
  count = var.enable_backup_plan ? 1 : 0

  name = local.backup_plan_name

  rule {
    rule_name         = "${local.backup_plan_name}-daily"
    target_vault_name = aws_backup_vault.rds[0].name
    schedule          = var.backup_plan_schedule
    start_window      = var.backup_plan_start_window_minutes
    completion_window = var.backup_plan_completion_window_minutes

    lifecycle {
      delete_after = var.backup_retention_days
    }

    dynamic "copy_action" {
      for_each = local.backup_copy_enabled ? [1] : []

      content {
        destination_vault_arn = var.backup_copy_destination_vault_arn

        lifecycle {
          delete_after = var.backup_copy_retention_days
        }
      }
    }
  }
}

resource "aws_backup_selection" "rds" {
  count = var.enable_backup_plan ? 1 : 0

  name         = "${local.backup_plan_name}-selection"
  iam_role_arn = aws_iam_role.backup[0].arn
  plan_id      = aws_backup_plan.rds[0].id
  resources    = [local.db_instance_arn]
}
