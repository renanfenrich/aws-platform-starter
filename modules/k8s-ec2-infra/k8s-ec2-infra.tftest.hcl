mock_provider "aws" {}

run "k8s_defaults" {
  command = plan

  variables {
    name_prefix                 = "test"
    cluster_name                = "test-k8s"
    vpc_id                      = "vpc-12345678"
    vpc_cidr                    = "10.0.0.0/16"
    private_subnet_ids          = ["subnet-123", "subnet-456"]
    alb_security_group_id       = "sg-alb12345"
    alb_target_group_arn        = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/1234567890abcdef"
    control_plane_instance_type = "t3.small"
    worker_instance_type        = "t3.small"
    worker_desired_capacity     = 1
    worker_min_size             = 1
    worker_max_size             = 2
    ami_id                      = "ami-1234567890abcdef0"
    enable_detailed_monitoring  = false
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
    target = data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.instance_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.kms_key
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.control_plane_ssm_join
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.worker_ssm_join
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = aws_instance.control_plane.associate_public_ip_address == false
    error_message = "expected control plane instance to avoid public IPs"
  }

  assert {
    condition     = aws_kms_key.join_parameter.enable_key_rotation == true
    error_message = "expected KMS key rotation to be enabled"
  }

  assert {
    condition     = aws_security_group.control_plane.tags["Project"] == "test"
    error_message = "expected Project tag on control plane security group"
  }

  assert {
    condition     = aws_security_group.control_plane.tags["Name"] == "test-k8s-control-plane"
    error_message = "expected control plane security group Name tag to use name_prefix"
  }

  assert {
    condition = length([
      for rule in [
        aws_security_group_rule.control_plane_from_workers,
        aws_security_group_rule.control_plane_self,
        aws_security_group_rule.control_plane_egress_vpc,
        aws_security_group_rule.control_plane_egress_https,
        aws_security_group_rule.worker_from_control_plane,
        aws_security_group_rule.worker_from_self,
        aws_security_group_rule.worker_from_alb,
        aws_security_group_rule.worker_egress_vpc,
        aws_security_group_rule.worker_egress_https
      ] : rule
      if rule.type == "ingress" &&
      contains(coalescelist(rule.cidr_blocks, []), "0.0.0.0/0") &&
      (rule.from_port == 22 || rule.to_port == 22)
    ]) == 0
    error_message = "expected no public SSH ingress rules"
  }
}

run "k8s_invalid_nodeport" {
  command = plan

  variables {
    name_prefix                 = "test"
    cluster_name                = "test-k8s"
    vpc_id                      = "vpc-12345678"
    vpc_cidr                    = "10.0.0.0/16"
    private_subnet_ids          = ["subnet-123", "subnet-456"]
    alb_security_group_id       = "sg-alb12345"
    alb_target_group_arn        = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/1234567890abcdef"
    control_plane_instance_type = "t3.small"
    worker_instance_type        = "t3.small"
    worker_desired_capacity     = 1
    worker_min_size             = 1
    worker_max_size             = 2
    ingress_nodeport            = 20000
    ami_id                      = "ami-1234567890abcdef0"
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
    target = data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.instance_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.kms_key
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.control_plane_ssm_join
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.worker_ssm_join
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  expect_failures = [var.ingress_nodeport]
}
