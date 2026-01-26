data "aws_caller_identity" "current" {}

locals {
  vault_name_input = var.vault_name_override == null ? "" : trimspace(var.vault_name_override)
  vault_name       = length(local.vault_name_input) > 0 ? var.vault_name_override : "${var.name_prefix}-backup"
}

data "aws_iam_policy_document" "vault_kms" {
  statement {
    sid = "AllowRootAccount"

    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid = "AllowBackupService"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_kms_key" "vault" {
  description             = "KMS key for ${local.vault_name} backup vault"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.vault_kms.json

  tags = var.tags
}

resource "aws_kms_alias" "vault" {
  name          = "alias/${local.vault_name}"
  target_key_id = aws_kms_key.vault.key_id
}

resource "aws_backup_vault" "this" {
  name        = local.vault_name
  kms_key_arn = aws_kms_key.vault.arn

  tags = var.tags
}
