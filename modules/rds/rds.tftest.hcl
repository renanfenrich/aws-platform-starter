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
