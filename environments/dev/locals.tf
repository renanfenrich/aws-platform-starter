locals {
  name_prefix                = "${var.project_name}-${var.environment}"
  azs                        = slice(data.aws_availability_zones.available.names, 0, 2)
  platform_is_ecs            = var.platform == "ecs"
  platform_is_k8s            = var.platform == "k8s_self_managed"
  platform_is_eks            = var.platform == "eks"
  platform_is_k8s_or_eks     = local.platform_is_k8s || local.platform_is_eks
  ingress_nodeport           = local.platform_is_eks ? var.eks_ingress_nodeport : var.k8s_ingress_nodeport
  alb_target_port            = local.platform_is_k8s_or_eks ? local.ingress_nodeport : var.container_port
  alb_target_type            = local.platform_is_k8s_or_eks ? "instance" : "ip"
  ecs_cluster_name           = "${local.name_prefix}-ecs"
  ec2_desired_capacity       = var.ec2_desired_capacity != null ? var.ec2_desired_capacity : var.desired_count
  ec2_min_size               = var.ec2_min_size != null ? var.ec2_min_size : local.ec2_desired_capacity
  ec2_max_size               = var.ec2_max_size != null ? var.ec2_max_size : local.ec2_desired_capacity
  ec2_capacity_provider_name = "${local.name_prefix}-ecs-ec2"
  base_capacity_providers    = ["FARGATE", "FARGATE_SPOT"]
  ecs_capacity_providers     = var.ecs_capacity_mode == "ec2" ? concat(local.base_capacity_providers, [local.ec2_capacity_provider_name]) : local.base_capacity_providers
  ecs_default_capacity_provider_strategy = var.ecs_capacity_mode == "fargate" ? [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 0
    }
    ] : var.ecs_capacity_mode == "fargate_spot" ? [
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 2
      base              = 0
    },
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 0
    }
    ] : [
    {
      capacity_provider = local.ec2_capacity_provider_name
      weight            = 1
      base              = 0
    }
  ]
  ecs_service_capacity_provider_strategy = local.ecs_default_capacity_provider_strategy
  ecs_requires_compatibilities           = var.ecs_capacity_mode == "ec2" ? ["EC2"] : ["FARGATE"]
  ecs_ec2_enabled                        = local.platform_is_ecs && var.ecs_capacity_mode == "ec2"
  enable_ec2_cpu_alarm                   = local.ecs_ec2_enabled || local.platform_is_k8s || local.platform_is_eks
  k8s_cluster_name                       = "${local.name_prefix}-k8s"
  eks_cluster_name                       = "${local.name_prefix}-eks"
  k8s_join_parameter_name                = length(trimspace(var.k8s_join_parameter_name)) > 0 ? var.k8s_join_parameter_name : "/${local.name_prefix}/k8s/join-command"
  budget_cost_filters = {
    TagKeyValue = [format("Environment$%s", var.environment)]
  }
  budget_sns_topic_arn     = length(trimspace(var.budget_sns_topic_arn)) > 0 ? var.budget_sns_topic_arn : var.alarm_sns_topic_arn
  budget_hard_limit_usd    = var.budget_limit_usd * (var.budget_hard_limit_percent / 100)
  estimated_cost_label     = var.estimated_monthly_cost != null ? format("%.2f", var.estimated_monthly_cost) : "unset"
  container_image_input    = var.container_image == null ? "" : trimspace(var.container_image)
  container_image_override = length(local.container_image_input) > 0
  tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      Service     = var.service_name
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "Terraform"
      Repository  = "aws-platform-starter"
    },
    var.additional_tags
  )
  resolved_container_image = local.container_image_override ? var.container_image : "${module.ecr.repository_url}:${var.image_tag}"
}

locals {
  container_environment = {
    APP_ENV = var.environment
  }

  container_secrets = {
    DB_SECRET = module.rds.master_user_secret_arn
  }
}
