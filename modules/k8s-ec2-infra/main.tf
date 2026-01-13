locals {
  ami_id                  = var.ami_id != null ? var.ami_id : data.aws_ssm_parameter.k8s_ami[0].value
  raw_join_parameter_name = length(trimspace(var.join_parameter_name)) > 0 ? var.join_parameter_name : "/${var.name_prefix}/k8s/join-command"
  join_parameter_name     = startswith(local.raw_join_parameter_name, "/") ? local.raw_join_parameter_name : "/${local.raw_join_parameter_name}"
  k8s_version_minor       = join(".", slice(split(".", var.k8s_version), 0, 2))
  join_parameter_arn      = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter${local.join_parameter_name}"
  control_plane_tag_name  = "${var.name_prefix}-k8s-control-plane"
  worker_tag_name         = "${var.name_prefix}-k8s-worker"
  k8s_log_group_name      = "/aws/k8s/${var.name_prefix}"

  control_plane_user_data = templatefile("${path.module}/templates/control-plane-user-data.sh.tpl", {
    aws_region                = data.aws_region.current.id
    cluster_name              = var.cluster_name
    ingress_nodeport          = var.ingress_nodeport
    join_parameter_name       = local.join_parameter_name
    join_parameter_kms_key_id = aws_kms_key.join_parameter.arn
    k8s_version_minor         = local.k8s_version_minor
    log_group_name            = local.k8s_log_group_name
    pod_cidr                  = var.pod_cidr
    service_cidr              = var.service_cidr
  })
  worker_user_data = templatefile("${path.module}/templates/worker-user-data.sh.tpl", {
    aws_region          = data.aws_region.current.id
    join_parameter_name = local.join_parameter_name
    k8s_version_minor   = local.k8s_version_minor
    log_group_name      = local.k8s_log_group_name
  })

  control_plane_user_data_base64 = base64encode(local.control_plane_user_data)
  worker_user_data_base64        = base64encode(local.worker_user_data)
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "k8s_ami" {
  count = var.ami_id == null ? 1 : 0
  name  = var.ami_ssm_parameter
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

resource "aws_iam_role" "control_plane" {
  name               = "${var.name_prefix}-k8s-control-plane"
  assume_role_policy = data.aws_iam_policy_document.instance_assume.json

  tags = var.tags
}

resource "aws_iam_role" "worker" {
  name               = "${var.name_prefix}-k8s-worker"
  assume_role_policy = data.aws_iam_policy_document.instance_assume.json

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "k8s_app" {
  name              = local.k8s_log_group_name
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

data "aws_iam_policy_document" "k8s_cloudwatch_logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.k8s_app.arn,
      "${aws_cloudwatch_log_group.k8s_app.arn}:*"
    ]
  }
}

resource "aws_iam_policy" "k8s_cloudwatch_logs" {
  name   = "${var.name_prefix}-k8s-logs"
  policy = data.aws_iam_policy_document.k8s_cloudwatch_logs.json
}

resource "aws_iam_role_policy_attachment" "control_plane_cloudwatch_logs" {
  role       = aws_iam_role.control_plane.name
  policy_arn = aws_iam_policy.k8s_cloudwatch_logs.arn
}

resource "aws_iam_role_policy_attachment" "worker_cloudwatch_logs" {
  role       = aws_iam_role.worker.name
  policy_arn = aws_iam_policy.k8s_cloudwatch_logs.arn
}

data "aws_iam_policy_document" "kms_key" {
  statement {
    sid       = "AllowRoot"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid = "AllowK8sRoles"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.control_plane.arn, aws_iam_role.worker.arn]
    }
  }
}

resource "aws_kms_key" "join_parameter" {
  description             = "KMS key for ${var.name_prefix} kubeadm join parameter"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key.json

  tags = var.tags
}

resource "aws_kms_alias" "join_parameter" {
  name          = "alias/${var.name_prefix}-k8s-join"
  target_key_id = aws_kms_key.join_parameter.key_id
}

data "aws_iam_policy_document" "control_plane_ssm_join" {
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter"
    ]
    resources = [local.join_parameter_arn]
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.join_parameter.arn]
  }
}

resource "aws_iam_policy" "control_plane_ssm_join" {
  name   = "${var.name_prefix}-k8s-join-write"
  policy = data.aws_iam_policy_document.control_plane_ssm_join.json
}

resource "aws_iam_role_policy_attachment" "control_plane_ssm_join" {
  role       = aws_iam_role.control_plane.name
  policy_arn = aws_iam_policy.control_plane_ssm_join.arn
}

data "aws_iam_policy_document" "worker_ssm_join" {
  statement {
    actions = [
      "ssm:GetParameter"
    ]
    resources = [local.join_parameter_arn]
  }

  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.join_parameter.arn]
  }
}

resource "aws_iam_policy" "worker_ssm_join" {
  name   = "${var.name_prefix}-k8s-join-read"
  policy = data.aws_iam_policy_document.worker_ssm_join.json
}

resource "aws_iam_role_policy_attachment" "worker_ssm_join" {
  role       = aws_iam_role.worker.name
  policy_arn = aws_iam_policy.worker_ssm_join.arn
}

resource "aws_iam_role_policy_attachment" "control_plane_ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.control_plane.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "worker_ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.worker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "control_plane_ecr_read" {
  role       = aws_iam_role.control_plane.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "worker_ecr_read" {
  role       = aws_iam_role.worker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "control_plane_extra" {
  for_each = toset(var.instance_role_policy_arns)

  role       = aws_iam_role.control_plane.name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "worker_extra" {
  for_each = toset(var.instance_role_policy_arns)

  role       = aws_iam_role.worker.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "control_plane" {
  name = "${var.name_prefix}-k8s-control-plane"
  role = aws_iam_role.control_plane.name
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.name_prefix}-k8s-worker"
  role = aws_iam_role.worker.name
}

resource "aws_security_group" "control_plane" {
  name        = "${var.name_prefix}-k8s-control-plane"
  description = "Kubernetes control plane security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-k8s-control-plane"
  })
}

resource "aws_security_group" "worker" {
  name        = "${var.name_prefix}-k8s-worker"
  description = "Kubernetes worker security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-k8s-worker"
  })
}

resource "aws_security_group_rule" "control_plane_from_workers" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker.id
  security_group_id        = aws_security_group.control_plane.id
  description              = "Kubernetes API server from worker nodes"
}

resource "aws_security_group_rule" "control_plane_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.control_plane.id
  description       = "Control plane self traffic"
}

resource "aws_security_group_rule" "control_plane_egress_vpc" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.control_plane.id
  description       = "Control plane egress within VPC"
}

resource "aws_security_group_rule" "control_plane_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.control_plane.id
  description       = "Control plane egress for HTTPS"
}

resource "aws_security_group_rule" "worker_from_control_plane" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane.id
  security_group_id        = aws_security_group.worker.id
  description              = "Control plane traffic to worker nodes"
}

resource "aws_security_group_rule" "worker_from_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.worker.id
  description       = "Worker node self traffic"
}

resource "aws_security_group_rule" "worker_from_alb" {
  type                     = "ingress"
  from_port                = var.ingress_nodeport
  to_port                  = var.ingress_nodeport
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group_id
  security_group_id        = aws_security_group.worker.id
  description              = "ALB traffic to ingress NodePort"
}

resource "aws_security_group_rule" "worker_egress_vpc" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.worker.id
  description       = "Worker node egress within VPC"
}

resource "aws_security_group_rule" "worker_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.worker.id
  description       = "Worker node egress for HTTPS"
}

resource "aws_instance" "control_plane" {
  ami                         = local.ami_id
  instance_type               = var.control_plane_instance_type
  subnet_id                   = var.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.control_plane.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.control_plane.name
  user_data_base64            = local.control_plane_user_data_base64
  monitoring                  = var.enable_detailed_monitoring

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(var.tags, {
    Name = local.control_plane_tag_name
  })
}

resource "aws_launch_template" "worker" {
  name_prefix   = "${var.name_prefix}-k8s-worker-"
  image_id      = local.ami_id
  instance_type = var.worker_instance_type
  user_data     = local.worker_user_data_base64

  iam_instance_profile {
    name = aws_iam_instance_profile.worker.name
  }

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = false
    security_groups             = [aws_security_group.worker.id]
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
      Name = local.worker_tag_name
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = var.tags
  }
}

resource "aws_autoscaling_group" "worker" {
  name                      = "${var.name_prefix}-k8s-worker-asg"
  max_size                  = var.worker_max_size
  min_size                  = var.worker_min_size
  desired_capacity          = var.worker_desired_capacity
  vpc_zone_identifier       = var.private_subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = var.health_check_grace_period_seconds
  target_group_arns         = [var.alb_target_group_arn]

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(var.tags, { Name = local.worker_tag_name })
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
