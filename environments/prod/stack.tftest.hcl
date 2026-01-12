mock_provider "aws" {}

run "prod_ecs_fargate" {
  command = plan

  variables {
    service_name                     = "platform"
    owner                            = "platform-team"
    cost_center                      = "platform"
    cost_posture                     = "stability_first"
    budget_limit_usd                 = 400
    budget_warning_threshold_percent = 75
    budget_hard_limit_percent        = 90
    budget_notification_emails       = ["platform-alerts@example.com"]
    estimated_monthly_cost           = 200
    platform                         = "ecs"
    ecs_capacity_mode                = "fargate"
    acm_certificate_arn              = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
    alb_access_logs_bucket           = "example-alb-access-logs"
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a", "us-east-1b"]
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.ecs[0].data.aws_region.current
    values = {
      name = "us-east-1"
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

  assert {
    condition     = output.platform == "ecs"
    error_message = "expected platform output to be ecs"
  }

  assert {
    condition     = length(module.ecs) == 1
    error_message = "expected ECS module to be created"
  }

  assert {
    condition     = length(module.k8s_ec2_infra) == 0
    error_message = "expected k8s module to be skipped"
  }

  assert {
    condition     = length(module.ecs_ec2_capacity) == 0
    error_message = "expected EC2 capacity provider module to be skipped"
  }

  assert {
    condition     = module.alb.http_listener_arn == null
    error_message = "expected HTTP listener to be disabled in prod"
  }

  assert {
    condition     = module.alb.alb_access_logs_bucket == var.alb_access_logs_bucket
    error_message = "expected ALB access logs bucket to match configuration"
  }

  assert {
    condition     = module.network.flow_logs_log_group_name != null
    error_message = "expected VPC flow logs to be enabled in prod"
  }

  assert {
    condition     = aws_security_group.app[0].tags["Project"] == var.project_name
    error_message = "expected app security group to include Project tag"
  }

  assert {
    condition     = aws_security_group.app[0].tags["Environment"] == var.environment
    error_message = "expected app security group to include Environment tag"
  }

  assert {
    condition     = aws_security_group.app[0].tags["Service"] == var.service_name
    error_message = "expected app security group to include Service tag"
  }

  assert {
    condition     = aws_security_group.app[0].tags["Owner"] == var.owner
    error_message = "expected app security group to include Owner tag"
  }

  assert {
    condition     = aws_security_group.app[0].tags["CostCenter"] == var.cost_center
    error_message = "expected app security group to include CostCenter tag"
  }

  assert {
    condition     = output.budget_name != ""
    error_message = "expected budget to be configured"
  }

  assert {
    condition     = output.budget_hard_limit_usd > 0
    error_message = "expected budget hard limit to be greater than 0"
  }
}

run "prod_ecs_fargate_spot" {
  command = plan

  variables {
    service_name                     = "platform"
    owner                            = "platform-team"
    cost_center                      = "platform"
    cost_posture                     = "stability_first"
    allow_spot_in_prod               = true
    budget_limit_usd                 = 400
    budget_warning_threshold_percent = 75
    budget_hard_limit_percent        = 90
    budget_notification_emails       = ["platform-alerts@example.com"]
    estimated_monthly_cost           = 200
    platform                         = "ecs"
    ecs_capacity_mode                = "fargate_spot"
    acm_certificate_arn              = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
    alb_access_logs_bucket           = "example-alb-access-logs"
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a", "us-east-1b"]
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.ecs[0].data.aws_region.current
    values = {
      name = "us-east-1"
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

  assert {
    condition     = length(module.ecs) == 1
    error_message = "expected ECS module to be created"
  }

  assert {
    condition     = module.ecr.repository_name != ""
    error_message = "expected ECR repository to be created"
  }

  assert {
    condition     = module.ecr.image_tag_mutability == "IMMUTABLE"
    error_message = "expected ECR repository to default to immutable tags"
  }

  assert {
    condition     = module.ecr.scan_on_push == true
    error_message = "expected ECR repository scan_on_push to be enabled"
  }

  assert {
    condition     = length(module.ecs_ec2_capacity) == 0
    error_message = "expected EC2 capacity provider module to be skipped"
  }
}

run "prod_ecs_ec2" {
  command = plan

  variables {
    service_name                     = "platform"
    owner                            = "platform-team"
    cost_center                      = "platform"
    cost_posture                     = "stability_first"
    budget_limit_usd                 = 400
    budget_warning_threshold_percent = 75
    budget_hard_limit_percent        = 90
    budget_notification_emails       = ["platform-alerts@example.com"]
    estimated_monthly_cost           = 200
    platform                         = "ecs"
    ecs_capacity_mode                = "ec2"
    acm_certificate_arn              = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
    alb_access_logs_bucket           = "example-alb-access-logs"
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a", "us-east-1b"]
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.ecs[0].data.aws_region.current
    values = {
      name = "us-east-1"
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
    target = module.ecs_ec2_capacity[0].data.aws_ssm_parameter.ecs_ami
    values = {
      value = "ami-1234567890abcdef0"
    }
  }

  override_data {
    target = module.ecs_ec2_capacity[0].data.aws_iam_policy_document.instance_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = length(module.ecs) == 1
    error_message = "expected ECS module to be created"
  }

  assert {
    condition     = length(module.ecs_ec2_capacity) == 1
    error_message = "expected EC2 capacity provider module to be created"
  }
}

run "prod_k8s" {
  command = plan

  variables {
    service_name                     = "platform"
    owner                            = "platform-team"
    cost_center                      = "platform"
    cost_posture                     = "stability_first"
    budget_limit_usd                 = 400
    budget_warning_threshold_percent = 75
    budget_hard_limit_percent        = 90
    budget_notification_emails       = ["platform-alerts@example.com"]
    estimated_monthly_cost           = 200
    platform                         = "k8s_self_managed"
    acm_certificate_arn              = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
    alb_access_logs_bucket           = "example-alb-access-logs"
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a", "us-east-1b"]
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.k8s_ec2_infra[0].data.aws_region.current
    values = {
      name = "us-east-1"
    }
  }

  override_data {
    target = module.k8s_ec2_infra[0].data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = module.k8s_ec2_infra[0].data.aws_ssm_parameter.k8s_ami[0]
    values = {
      value = "ami-1234567890abcdef0"
    }
  }

  override_data {
    target = module.k8s_ec2_infra[0].data.aws_iam_policy_document.instance_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.k8s_ec2_infra[0].data.aws_iam_policy_document.kms_key
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.k8s_ec2_infra[0].data.aws_iam_policy_document.control_plane_ssm_join
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.k8s_ec2_infra[0].data.aws_iam_policy_document.worker_ssm_join
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = output.platform == "k8s_self_managed"
    error_message = "expected platform output to be k8s_self_managed"
  }

  assert {
    condition     = module.ecr.repository_name != ""
    error_message = "expected ECR repository to be created"
  }

  assert {
    condition     = module.ecr.image_tag_mutability == "IMMUTABLE"
    error_message = "expected ECR repository to default to immutable tags"
  }

  assert {
    condition     = module.ecr.scan_on_push == true
    error_message = "expected ECR repository scan_on_push to be enabled"
  }

  assert {
    condition     = length(module.k8s_ec2_infra) == 1
    error_message = "expected k8s module to be created"
  }

  assert {
    condition     = length(module.ecs) == 0
    error_message = "expected ECS module to be skipped"
  }

  assert {
    condition     = output.ecs_cluster_name == null
    error_message = "expected ecs cluster output to be null for k8s"
  }
}

run "prod_invalid_allow_http" {
  command = plan

  variables {
    service_name                     = "platform"
    owner                            = "platform-team"
    cost_center                      = "platform"
    cost_posture                     = "stability_first"
    budget_limit_usd                 = 400
    budget_warning_threshold_percent = 75
    budget_hard_limit_percent        = 90
    budget_notification_emails       = ["platform-alerts@example.com"]
    estimated_monthly_cost           = 200
    allow_http                       = true
    acm_certificate_arn              = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
    alb_access_logs_bucket           = "example-alb-access-logs"
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a", "us-east-1b"]
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.ecs[0].data.aws_region.current
    values = {
      name = "us-east-1"
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

  expect_failures = [var.allow_http]
}

run "prod_spot_blocked_without_override" {
  command = plan

  variables {
    service_name                     = "platform"
    owner                            = "platform-team"
    cost_center                      = "platform"
    cost_posture                     = "stability_first"
    budget_limit_usd                 = 400
    budget_warning_threshold_percent = 75
    budget_hard_limit_percent        = 90
    budget_notification_emails       = ["platform-alerts@example.com"]
    estimated_monthly_cost           = 200
    platform                         = "ecs"
    ecs_capacity_mode                = "fargate_spot"
    acm_certificate_arn              = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
    alb_access_logs_bucket           = "example-alb-access-logs"
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a", "us-east-1b"]
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.ecs[0].data.aws_region.current
    values = {
      name = "us-east-1"
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

  expect_failures = [var.ecs_capacity_mode]
}

run "prod_invalid_cost_posture" {
  command = plan

  variables {
    service_name                     = "platform"
    owner                            = "platform-team"
    cost_center                      = "platform"
    cost_posture                     = "cost_optimized"
    budget_limit_usd                 = 400
    budget_warning_threshold_percent = 75
    budget_hard_limit_percent        = 90
    budget_notification_emails       = ["platform-alerts@example.com"]
    estimated_monthly_cost           = 200
    platform                         = "ecs"
    acm_certificate_arn              = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
    alb_access_logs_bucket           = "example-alb-access-logs"
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a", "us-east-1b"]
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.ecs[0].data.aws_region.current
    values = {
      name = "us-east-1"
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

  expect_failures = [var.cost_posture]
}

run "prod_cost_enforcement_block" {
  command = plan

  variables {
    service_name                     = "platform"
    owner                            = "platform-team"
    cost_center                      = "platform"
    cost_posture                     = "stability_first"
    budget_limit_usd                 = 100
    budget_warning_threshold_percent = 80
    budget_hard_limit_percent        = 90
    budget_notification_emails       = ["platform-alerts@example.com"]
    estimated_monthly_cost           = 200
    platform                         = "ecs"
    ecs_capacity_mode                = "fargate"
    acm_certificate_arn              = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
    alb_access_logs_bucket           = "example-alb-access-logs"
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a", "us-east-1b"]
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.network.data.aws_iam_policy_document.flow_logs
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.ecs[0].data.aws_region.current
    values = {
      name = "us-east-1"
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

  expect_failures = [terraform_data.cost_enforcement]
}
