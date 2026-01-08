mock_provider "aws" {}

run "network_plan" {
  command = plan

  variables {
    platform          = "ecs"
    ecs_capacity_mode = "fargate"
  }

  override_data {
    target = module.ecs[0].data.aws_iam_policy_document.task_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = length(module.network.public_subnet_ids) == 2
    error_message = "expected two public subnets"
  }

  assert {
    condition     = length(module.network.private_subnet_ids) == 2
    error_message = "expected two private subnets"
  }
}
