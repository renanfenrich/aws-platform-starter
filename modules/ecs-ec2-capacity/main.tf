locals {
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ssm_parameter.ecs_ami[0].value
  base_user_data = [
    "#!/bin/bash",
    "echo \"ECS_CLUSTER=${var.cluster_name}\" >> /etc/ecs/ecs.config"
  ]
  extra_user_data   = length(trimspace(var.user_data)) > 0 ? [var.user_data] : []
  user_data         = join("\n", concat(local.base_user_data, local.extra_user_data))
  user_data_base64  = base64encode(local.user_data)
  instance_tag_name = "${var.name_prefix}-ecs-node"
}

data "aws_ssm_parameter" "ecs_ami" {
  count = var.ami_id == null ? 1 : 0
  name  = var.ecs_ami_ssm_parameter
}

data "aws_iam_policy_document" "instance_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "${var.name_prefix}-ecs-ec2"
  assume_role_policy = data.aws_iam_policy_document.instance_assume.json

  tags = var.tags
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name_prefix}-ecs-ec2"
  role = aws_iam_role.instance.name
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "extra" {
  for_each = toset(var.instance_role_policy_arns)

  role       = aws_iam_role.instance.name
  policy_arn = each.value
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-ecs-ec2-"
  image_id      = local.ami_id
  instance_type = var.instance_type
  user_data     = local.user_data_base64

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = false
    security_groups             = [var.security_group_id]
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = local.instance_tag_name
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = var.tags
  }
}

resource "aws_autoscaling_group" "this" {
  name                      = "${var.name_prefix}-ecs-ec2-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.private_subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = var.health_check_grace_period_seconds
  protect_from_scale_in     = var.enable_managed_termination_protection

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(var.tags, { Name = local.instance_tag_name })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_capacity_provider" "this" {
  name = var.capacity_provider_name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.this.arn
    managed_termination_protection = var.enable_managed_termination_protection ? "ENABLED" : "DISABLED"

    managed_scaling {
      status                    = var.enable_managed_scaling ? "ENABLED" : "DISABLED"
      target_capacity           = var.capacity_provider_target_capacity
      minimum_scaling_step_size = var.capacity_provider_min_scaling_step_size
      maximum_scaling_step_size = var.capacity_provider_max_scaling_step_size
    }
  }

  tags = var.tags
}
