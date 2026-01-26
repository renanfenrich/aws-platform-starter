mock_provider "aws" {}

run "rds_defaults" {
  command = plan

  variables {
    name_prefix           = "test"
    vpc_id                = "vpc-12345678"
    private_subnet_ids    = ["subnet-123", "subnet-456"]
    app_security_group_id = "sg-app12345"
    db_name               = "appdb"
    db_username           = "appuser"
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

  assert {
    condition     = aws_db_instance.this[0].storage_encrypted == true
    error_message = "expected RDS storage encryption to be enabled"
  }

  assert {
    condition     = aws_db_instance.this[0].publicly_accessible == false
    error_message = "expected RDS to be private by default"
  }

  assert {
    condition     = aws_db_instance.this[0].manage_master_user_password == true
    error_message = "expected RDS to manage master user password"
  }

  assert {
    condition     = aws_kms_key.db[0].enable_key_rotation == true
    error_message = "expected RDS KMS key rotation to be enabled"
  }

  assert {
    condition     = aws_db_instance.this[0].identifier == "test-db"
    error_message = "expected RDS identifier to use name_prefix"
  }

  assert {
    condition     = aws_db_instance.this[0].tags["Project"] == "test"
    error_message = "expected Project tag on RDS instance"
  }
}

run "rds_additional_ingress" {
  command = plan

  variables {
    name_prefix           = "test"
    vpc_id                = "vpc-12345678"
    private_subnet_ids    = ["subnet-123", "subnet-456"]
    app_security_group_id = "sg-app12345"
    additional_ingress_security_group_ids = [
      "sg-extra1",
      "sg-extra2"
    ]
    db_name     = "appdb"
    db_username = "appuser"
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

  assert {
    condition     = length(aws_security_group_rule.db_ingress_additional) == 2
    error_message = "expected additional ingress rules to be created"
  }

  assert {
    condition     = aws_security_group_rule.db_ingress_additional[0].from_port == 5432
    error_message = "expected additional ingress rules to use the database port"
  }
}

run "rds_backup_enabled" {
  command = plan

  variables {
    name_prefix                       = "test"
    vpc_id                            = "vpc-12345678"
    private_subnet_ids                = ["subnet-123", "subnet-456"]
    app_security_group_id             = "sg-app12345"
    db_name                           = "appdb"
    db_username                       = "appuser"
    enable_backup_plan                = true
    backup_retention_days             = 14
    backup_plan_schedule              = "cron(0 5 * * ? *)"
    backup_copy_destination_vault_arn = "arn:aws:backup:us-west-2:123456789012:backup-vault:dr-vault"
    backup_copy_retention_days        = 30
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
    target = data.aws_iam_policy_document.backup_assume[0]
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.backup_kms[0]
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = length(aws_backup_plan.rds) == 1
    error_message = "expected AWS Backup plan to be created when enabled"
  }

  assert {
    condition     = length(aws_backup_selection.rds[0].resources) == 1
    error_message = "expected AWS Backup selection to include one resource"
  }

  assert {
    condition = anytrue([
      for rule in aws_backup_plan.rds[0].rule :
      anytrue([
        for action in rule.copy_action : action.destination_vault_arn == "arn:aws:backup:us-west-2:123456789012:backup-vault:dr-vault"
      ])
    ])
    error_message = "expected AWS Backup copy action to target the destination vault"
  }
}
