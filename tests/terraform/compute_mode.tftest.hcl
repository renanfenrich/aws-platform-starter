mock_provider "aws" {}

run "capacity_mode_fargate" {
  command = plan

  variables {
    ecs_capacity_mode = "fargate"
  }

  override_data {
    target = module.ecs.data.aws_iam_policy_document.task_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = length(module.ecs_ec2_capacity) == 0
    error_message = "expected EC2 capacity provider module to be skipped"
  }

  assert {
    condition     = contains(module.ecs.requires_compatibilities, "FARGATE")
    error_message = "expected ECS task definition to require FARGATE"
  }

  assert {
    condition     = length(module.ecs.capacity_provider_strategy) == 1
    error_message = "expected a single capacity provider strategy entry"
  }

  assert {
    condition     = contains([for strategy in module.ecs.capacity_provider_strategy : strategy.capacity_provider], "FARGATE")
    error_message = "expected ECS service to use FARGATE capacity provider"
  }
}

run "capacity_mode_fargate_spot" {
  command = plan

  variables {
    ecs_capacity_mode = "fargate_spot"
  }

  override_data {
    target = module.ecs.data.aws_iam_policy_document.task_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = length(module.ecs_ec2_capacity) == 0
    error_message = "expected EC2 capacity provider module to be skipped"
  }

  assert {
    condition     = contains(module.ecs.requires_compatibilities, "FARGATE")
    error_message = "expected ECS task definition to require FARGATE"
  }

  assert {
    condition     = contains([for strategy in module.ecs.capacity_provider_strategy : strategy.capacity_provider], "FARGATE_SPOT")
    error_message = "expected ECS service to prefer FARGATE_SPOT"
  }

  assert {
    condition     = contains([for strategy in module.ecs.capacity_provider_strategy : strategy.capacity_provider], "FARGATE")
    error_message = "expected ECS service to include FARGATE fallback"
  }
}

run "capacity_mode_ec2" {
  command = plan

  variables {
    ecs_capacity_mode = "ec2"
  }

  override_data {
    target = module.ecs.data.aws_iam_policy_document.task_assume
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
    condition     = length(module.ecs_ec2_capacity) == 1
    error_message = "expected EC2 capacity provider module to be created"
  }

  assert {
    condition     = contains(module.ecs.requires_compatibilities, "EC2")
    error_message = "expected ECS task definition to require EC2"
  }

  assert {
    condition     = contains([for strategy in module.ecs.capacity_provider_strategy : strategy.capacity_provider], local.ec2_capacity_provider_name)
    error_message = "expected ECS service to use the EC2 capacity provider"
  }
}
