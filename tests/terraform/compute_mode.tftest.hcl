mock_provider "aws" {}

run "compute_mode_ecs" {
  command = plan

  variables {
    compute_mode = "ecs"
  }

  override_data {
    target = module.ecs[0].data.aws_iam_policy_document.task_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = length(module.ecs) == 1
    error_message = "expected ECS module to be created"
  }

  assert {
    condition     = length(module.ec2_service) == 0
    error_message = "expected EC2 module to be skipped"
  }
}

run "compute_mode_ec2" {
  command = plan

  variables {
    compute_mode = "ec2"
  }

  override_data {
    target = module.ec2_service[0].data.aws_iam_policy_document.instance_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.ec2_service[0].data.aws_iam_policy_document.log_access
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = length(module.ecs) == 0
    error_message = "expected ECS module to be skipped"
  }

  assert {
    condition     = length(module.ec2_service) == 1
    error_message = "expected EC2 module to be created"
  }
}
