mock_provider "aws" {}

run "platform_ecs" {
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
    condition     = length(module.ecs) == 1
    error_message = "expected ECS module to be created when platform = ecs"
  }

  assert {
    condition     = length(module.k8s_ec2_infra) == 0
    error_message = "expected k8s module to be skipped when platform = ecs"
  }
}

run "platform_k8s" {
  command = plan

  variables {
    platform = "k8s_self_managed"
  }

  override_data {
    target = module.k8s_ec2_infra[0].data.aws_iam_policy_document.instance_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = length(module.ecs) == 0
    error_message = "expected ECS module to be skipped when platform = k8s_self_managed"
  }

  assert {
    condition     = length(module.k8s_ec2_infra) == 1
    error_message = "expected k8s module to be created when platform = k8s_self_managed"
  }
}

run "platform_eks" {
  command = plan

  variables {
    platform = "eks"
  }

  override_data {
    target = module.eks[0].data.aws_region.current
    values = {
      name = "us-east-1"
    }
  }

  override_data {
    target = module.eks[0].data.aws_iam_policy_document.cluster_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.eks[0].data.aws_iam_policy_document.node_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = length(module.ecs) == 0
    error_message = "expected ECS module to be skipped when platform = eks"
  }

  assert {
    condition     = length(module.k8s_ec2_infra) == 0
    error_message = "expected k8s module to be skipped when platform = eks"
  }

  assert {
    condition     = length(module.eks) == 1
    error_message = "expected eks module to be created when platform = eks"
  }
}
