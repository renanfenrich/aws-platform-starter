mock_provider "aws" {}

run "backup_vault_defaults" {
  command = plan

  variables {
    name_prefix = "test"
    tags = {
      Project     = "test"
      Environment = "test"
      Service     = "test"
      Owner       = "test"
      CostCenter  = "test"
      ManagedBy   = "Terraform"
      Repository  = "aws-platform-starter"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.vault_kms
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = aws_kms_key.vault.enable_key_rotation == true
    error_message = "expected backup vault KMS key rotation to be enabled"
  }

  assert {
    condition     = aws_backup_vault.this.name == "test-backup"
    error_message = "expected backup vault name to use name_prefix"
  }
}
