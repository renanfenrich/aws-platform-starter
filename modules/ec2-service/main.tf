locals {
  ami_id            = var.ami_id != null ? var.ami_id : data.aws_ami.default[0].id
  user_data_base64  = length(trimspace(var.user_data)) > 0 ? base64encode(var.user_data) : null
  instance_tag_name = "${var.name_prefix}-app"
}

data "aws_ami" "default" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
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
  name               = "${var.name_prefix}-ec2"
  assume_role_policy = data.aws_iam_policy_document.instance_assume.json

  tags = var.tags
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name_prefix}-ec2"
  role = aws_iam_role.instance.name
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "extra" {
  for_each = toset(var.instance_role_policy_arns)

  role       = aws_iam_role.instance.name
  policy_arn = each.value
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/${var.name_prefix}"
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

data "aws_iam_policy_document" "log_access" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]

    resources = [
      aws_cloudwatch_log_group.app.arn,
      "${aws_cloudwatch_log_group.app.arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "log_access" {
  name   = "${var.name_prefix}-ec2-logs"
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.log_access.json
}

data "aws_iam_policy_document" "secrets_access" {
  count = length(var.secrets_arns) > 0 ? 1 : 0

  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = var.secrets_arns
  }

  statement {
    actions   = ["kms:Decrypt"]
    resources = var.kms_key_arns
  }
}

resource "aws_iam_role_policy" "secrets_access" {
  count = length(var.secrets_arns) > 0 ? 1 : 0

  name   = "${var.name_prefix}-ec2-secrets"
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.secrets_access[0].json
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-lt-"
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
  name                      = "${var.name_prefix}-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.private_subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = var.health_check_grace_period_seconds
  target_group_arns         = [var.target_group_arn]

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
