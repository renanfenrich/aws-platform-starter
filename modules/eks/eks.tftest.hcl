mock_provider "aws" {}

run "eks_defaults" {
  command = plan

  variables {
    name_prefix           = "test"
    cluster_name          = "test-eks"
    vpc_id                = "vpc-12345678"
    vpc_cidr              = "10.0.0.0/16"
    private_subnet_ids    = ["subnet-123", "subnet-456"]
    alb_security_group_id = "sg-alb12345"
    alb_target_group_arn  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/1234567890abcdef"
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
    target = data.aws_ssm_parameter.admin_runner_ami[0]
    values = {
      value = "ami-1234567890abcdef0"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.cluster_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[] }"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.node_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[] }"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.admin_runner_assume[0]
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[] }"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.admin_runner_eks[0]
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[] }"
    }
  }

  assert {
    condition     = aws_eks_cluster.this.vpc_config[0].endpoint_private_access == true
    error_message = "expected EKS API endpoint private access to be enabled"
  }

  assert {
    condition     = aws_eks_cluster.this.vpc_config[0].endpoint_public_access == false
    error_message = "expected EKS API endpoint public access to be disabled"
  }

  assert {
    condition     = contains(aws_eks_node_group.this.subnet_ids, "subnet-123")
    error_message = "expected node group to include subnet-123"
  }

  assert {
    condition     = contains(aws_eks_node_group.this.subnet_ids, "subnet-456")
    error_message = "expected node group to include subnet-456"
  }

  assert {
    condition     = aws_security_group.node.tags["Project"] == "test"
    error_message = "expected Project tag on node security group"
  }

  assert {
    condition     = aws_instance.admin_runner[0].associate_public_ip_address == false
    error_message = "expected admin runner to avoid public IPs"
  }

  assert {
    condition = length([
      for rule in [
        aws_security_group_rule.cluster_from_nodes,
        aws_security_group_rule.cluster_from_admin_runner[0],
        aws_security_group_rule.node_from_cluster,
        aws_security_group_rule.node_from_self,
        aws_security_group_rule.node_from_alb
      ] : rule
      if rule.type == "ingress" &&
      contains(coalescelist(rule.cidr_blocks, []), "0.0.0.0/0") &&
      (rule.from_port == 22 || rule.to_port == 22)
    ]) == 0
    error_message = "expected no public SSH ingress rules"
  }
}
