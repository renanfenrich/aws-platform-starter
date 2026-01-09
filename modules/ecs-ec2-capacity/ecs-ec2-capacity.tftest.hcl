mock_provider "aws" {}

run "ecs_ec2_capacity_defaults" {
  command = plan

  variables {
    name_prefix                = "test"
    cluster_name               = "test-ecs"
    capacity_provider_name     = "test-ecs-ec2"
    private_subnet_ids         = ["subnet-123", "subnet-456"]
    security_group_id          = "sg-12345678"
    instance_type              = "t3.micro"
    desired_capacity           = 1
    min_size                   = 1
    max_size                   = 1
    ami_id                     = "ami-1234567890abcdef0"
    enable_detailed_monitoring = false
    tags = {
      Project     = "test"
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.instance_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = tostring(aws_launch_template.this.network_interfaces[0].associate_public_ip_address) == "false"
    error_message = "expected ECS EC2 instances to avoid public IPs"
  }

  assert {
    condition     = aws_launch_template.this.metadata_options[0].http_tokens == "required"
    error_message = "expected IMDSv2 to be required"
  }

  assert {
    condition     = contains([for tag in aws_autoscaling_group.this.tag : tag.key], "Project")
    error_message = "expected Project tag on ECS EC2 Auto Scaling group"
  }

  assert {
    condition     = alltrue([for tag in aws_autoscaling_group.this.tag : tag.key != "Name" || tag.value == "test-ecs-node"])
    error_message = "expected Name tag to use name_prefix"
  }

  assert {
    condition     = alltrue([for tag in aws_autoscaling_group.this.tag : tag.propagate_at_launch])
    error_message = "expected Auto Scaling group tags to propagate at launch"
  }
}
