mock_provider "aws" {}

run "dr_defaults_ecs" {
  command = plan

  variables {
    service_name                     = "platform"
    owner                            = "platform-team"
    cost_center                      = "platform"
    cost_posture                     = "cost_optimized"
    budget_limit_usd                 = 100
    budget_warning_threshold_percent = 85
    budget_hard_limit_percent        = 95
    budget_notification_emails       = ["platform-alerts@example.com"]
    estimated_monthly_cost           = 25
    platform                         = "ecs"
    ecs_capacity_mode                = "fargate"
    acm_certificate_arn              = ""
    db_instance_class                = "db.t4g.micro"
    alb_enable_public_ingress        = false
    enable_dr_backup_vault           = true
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-west-2a", "us-west-2b"]
    }
  }

  override_data {
    target = module.ecs[0].data.aws_region.current
    values = {
      name = "us-west-2"
    }
  }

  override_data {
    target = module.ecs[0].data.aws_iam_policy_document.task_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.ecs[0].data.aws_iam_policy_document.task_execution_exec[0]
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.ecs[0].data.aws_iam_policy_document.task_execution_secrets[0]
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.backup_vault[0].data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = module.backup_vault[0].data.aws_iam_policy_document.vault_kms
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = output.platform == "ecs"
    error_message = "expected platform output to be ecs"
  }

  assert {
    condition     = var.desired_count == 0
    error_message = "expected desired_count to default to 0 for DR"
  }

  assert {
    condition     = var.alb_enable_public_ingress == false
    error_message = "expected public ingress to be disabled by default"
  }

  assert {
    condition     = module.alb.https_listener_arn == null
    error_message = "expected HTTPS listener to be disabled when public ingress is off"
  }

  assert {
    condition     = var.enable_alarms == false
    error_message = "expected alarms to be disabled by default"
  }

  assert {
    condition     = var.db_backup_retention_period == 1
    error_message = "expected DR backup retention to default to 1 day"
  }

  assert {
    condition     = module.ecr.replication_enabled == false
    error_message = "expected ECR replication to be disabled by default"
  }

  assert {
    condition     = length(module.backup_vault) == 1
    error_message = "expected DR backup vault to be created by default"
  }
}
