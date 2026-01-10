mock_provider "aws" {}

run "ecs_defaults" {
  command = plan

  variables {
    name_prefix            = "test"
    environment            = "test"
    private_subnet_ids     = ["subnet-123", "subnet-456"]
    security_group_id      = "sg-12345678"
    target_group_arn       = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/1234567890abcdef"
    container_image        = "public.ecr.aws/nginx/nginx:latest"
    container_port         = 80
    enable_execute_command = true
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
    target = data.aws_region.current
    values = {
      name = "us-east-1"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.task_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.task_execution_exec[0]
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = aws_ecs_service.this.network_configuration[0].assign_public_ip == false
    error_message = "expected ECS tasks to avoid public IPs by default"
  }

  assert {
    condition     = contains([for setting in aws_ecs_cluster.this.setting : setting.name], "containerInsights")
    error_message = "expected container insights setting to be present"
  }

  assert {
    condition     = alltrue([for setting in aws_ecs_cluster.this.setting : setting.name != "containerInsights" || setting.value == "enabled"])
    error_message = "expected container insights to be enabled by default"
  }

  assert {
    condition     = aws_ecs_task_definition.this.family == "test-task"
    error_message = "expected task definition family to use name_prefix"
  }

  assert {
    condition     = aws_ecs_cluster.this.tags["Project"] == "test"
    error_message = "expected Project tag on ECS cluster"
  }
}

run "ecs_invalid_container_port" {
  command = plan

  variables {
    name_prefix            = "test"
    environment            = "test"
    private_subnet_ids     = ["subnet-123", "subnet-456"]
    security_group_id      = "sg-12345678"
    target_group_arn       = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/1234567890abcdef"
    container_image        = "public.ecr.aws/nginx/nginx:latest"
    container_port         = 70000
    enable_execute_command = false
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
    target = data.aws_region.current
    values = {
      name = "us-east-1"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.task_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  expect_failures = [var.container_port]
}

run "ecs_missing_kms_key_arns" {
  command = plan

  variables {
    name_prefix            = "test"
    environment            = "test"
    private_subnet_ids     = ["subnet-123", "subnet-456"]
    security_group_id      = "sg-12345678"
    target_group_arn       = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/1234567890abcdef"
    container_image        = "public.ecr.aws/nginx/nginx:latest"
    container_port         = 80
    secrets_arns           = ["arn:aws:secretsmanager:us-east-1:123456789012:secret:app"]
    enable_execute_command = false
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
    target = data.aws_region.current
    values = {
      name = "us-east-1"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.task_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.task_execution_secrets[0]
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  expect_failures = [var.kms_key_arns]
}
