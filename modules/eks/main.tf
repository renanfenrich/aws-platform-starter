locals {
  kubectl_version     = length(regexall("^\\d+\\.\\d+$", var.cluster_version)) > 0 ? "${var.cluster_version}.0" : var.cluster_version
  admin_runner_ami_id = var.admin_runner_ami_id != null ? var.admin_runner_ami_id : data.aws_ssm_parameter.admin_runner_ami[0].value
  admin_runner_user_data = templatefile("${path.module}/templates/admin-runner-user-data.sh.tpl", {
    aws_region      = data.aws_region.current.id
    cluster_name    = var.cluster_name
    kubectl_version = local.kubectl_version
  })
  admin_runner_user_data_base64 = base64encode(local.admin_runner_user_data)
  node_group_name               = "${var.name_prefix}-eks-nodes"
  cluster_tag_name              = "${var.name_prefix}-eks-cluster"
  node_tag_name                 = "${var.name_prefix}-eks-node"
  admin_runner_tag_name         = "${var.name_prefix}-eks-admin"
}

data "aws_region" "current" {}

data "aws_ssm_parameter" "admin_runner_ami" {
  count = var.admin_runner_ami_id == null ? 1 : 0
  name  = var.admin_runner_ami_ssm_parameter
}

data "aws_iam_policy_document" "cluster_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.name_prefix}-eks-cluster"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "node_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.name_prefix}-eks-node"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_ssm" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_security_group" "cluster" {
  name        = "${var.name_prefix}-eks-cluster"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = local.cluster_tag_name
  })
}

resource "aws_security_group" "node" {
  name        = "${var.name_prefix}-eks-node"
  description = "EKS node security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = local.node_tag_name
  })
}

resource "aws_security_group" "admin_runner" {
  count = var.enable_admin_runner ? 1 : 0

  name        = "${var.name_prefix}-eks-admin"
  description = "EKS admin runner security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = local.admin_runner_tag_name
  })
}

resource "aws_security_group_rule" "cluster_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node.id
  security_group_id        = aws_security_group.cluster.id
  description              = "EKS API access from nodes"
}

resource "aws_security_group_rule" "cluster_from_admin_runner" {
  count = var.enable_admin_runner ? 1 : 0

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.admin_runner[0].id
  security_group_id        = aws_security_group.cluster.id
  description              = "EKS API access from admin runner"
}

resource "aws_security_group_rule" "cluster_egress_vpc" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.cluster.id
  description       = "EKS control plane egress within VPC"
}

resource "aws_security_group_rule" "node_from_cluster" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.node.id
  description              = "Control plane traffic to nodes"
}

resource "aws_security_group_rule" "node_from_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.node.id
  description       = "Node to node traffic"
}

resource "aws_security_group_rule" "node_from_alb" {
  type                     = "ingress"
  from_port                = var.ingress_nodeport
  to_port                  = var.ingress_nodeport
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group_id
  security_group_id        = aws_security_group.node.id
  description              = "ALB traffic to ingress NodePort"
}

resource "aws_security_group_rule" "node_egress_vpc" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.node.id
  description       = "Node egress within VPC"
}

resource "aws_security_group_rule" "node_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.node.id
  description       = "Node egress for HTTPS"
}

resource "aws_security_group_rule" "admin_runner_egress_vpc" {
  count = var.enable_admin_runner ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.admin_runner[0].id
  description       = "Admin runner egress within VPC"
}

resource "aws_security_group_rule" "admin_runner_egress_https" {
  count = var.enable_admin_runner ? 1 : 0

  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.admin_runner[0].id
  description       = "Admin runner egress for HTTPS"
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access_cidrs
  }

  tags = merge(var.tags, {
    Name = local.cluster_tag_name
  })

  depends_on = [aws_iam_role_policy_attachment.cluster]
}

resource "aws_launch_template" "node" {
  name_prefix = "${var.name_prefix}-eks-node-"

  vpc_security_group_ids = [aws_security_group.node.id]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = local.node_tag_name
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = var.tags
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = local.node_group_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  version         = var.cluster_version
  instance_types  = [var.node_instance_type]
  ami_type        = var.node_ami_type
  disk_size       = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired_capacity
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.node.id
    version = "$Latest"
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
    aws_iam_role_policy_attachment.node_ssm
  ]
}

resource "aws_autoscaling_attachment" "node_group" {
  autoscaling_group_name = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name
  lb_target_group_arn    = var.alb_target_group_arn
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

data "aws_iam_policy_document" "admin_runner_assume" {
  count = var.enable_admin_runner ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "admin_runner" {
  count = var.enable_admin_runner ? 1 : 0

  name               = "${var.name_prefix}-eks-admin"
  assume_role_policy = data.aws_iam_policy_document.admin_runner_assume[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "admin_runner_ssm" {
  count = var.enable_admin_runner ? 1 : 0

  role       = aws_iam_role.admin_runner[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "admin_runner_eks" {
  count = var.enable_admin_runner ? 1 : 0

  statement {
    actions = ["eks:DescribeCluster"]
    resources = [
      aws_eks_cluster.this.arn
    ]
  }
}

resource "aws_iam_policy" "admin_runner_eks" {
  count = var.enable_admin_runner ? 1 : 0

  name   = "${var.name_prefix}-eks-admin-access"
  policy = data.aws_iam_policy_document.admin_runner_eks[0].json
}

resource "aws_iam_role_policy_attachment" "admin_runner_eks" {
  count = var.enable_admin_runner ? 1 : 0

  role       = aws_iam_role.admin_runner[0].name
  policy_arn = aws_iam_policy.admin_runner_eks[0].arn
}

resource "aws_iam_instance_profile" "admin_runner" {
  count = var.enable_admin_runner ? 1 : 0

  name = "${var.name_prefix}-eks-admin"
  role = aws_iam_role.admin_runner[0].name
}

resource "aws_instance" "admin_runner" {
  count = var.enable_admin_runner ? 1 : 0

  ami                         = local.admin_runner_ami_id
  instance_type               = var.admin_runner_instance_type
  subnet_id                   = var.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.admin_runner[0].id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.admin_runner[0].name
  user_data_base64            = local.admin_runner_user_data_base64

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(var.tags, {
    Name = local.admin_runner_tag_name
  })
}

resource "aws_eks_access_entry" "admin_runner" {
  count = var.enable_admin_runner ? 1 : 0

  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = aws_iam_role.admin_runner[0].arn
  kubernetes_groups = ["system:masters"]
  type              = "STANDARD"

  tags = var.tags
}
