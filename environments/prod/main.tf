provider "aws" {
  region              = var.aws_region
  allowed_account_ids = length(var.allowed_account_ids) > 0 ? var.allowed_account_ids : null

  default_tags {
    tags = local.tags
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix                = "${var.project_name}-${var.environment}"
  azs                        = slice(data.aws_availability_zones.available.names, 0, 2)
  platform_is_ecs            = var.platform == "ecs"
  platform_is_k8s            = var.platform == "k8s_self_managed"
  platform_is_eks            = var.platform == "eks"
  alb_target_port            = local.platform_is_k8s ? var.k8s_ingress_nodeport : var.container_port
  alb_target_type            = local.platform_is_k8s ? "instance" : "ip"
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
  enable_ec2_cpu_alarm                   = local.ecs_ec2_enabled || local.platform_is_k8s
  k8s_cluster_name                       = "${local.name_prefix}-k8s"
  k8s_join_parameter_name                = length(trimspace(var.k8s_join_parameter_name)) > 0 ? var.k8s_join_parameter_name : "/${local.name_prefix}/k8s/join-command"
  budget_cost_filters = {
    TagKeyValue = [format("Environment$%s", var.environment)]
  }
  budget_sns_topic_arn     = length(trimspace(var.budget_sns_topic_arn)) > 0 ? var.budget_sns_topic_arn : var.alarm_sns_topic_arn
  budget_hard_limit_usd    = var.budget_limit_usd * (var.budget_hard_limit_percent / 100)
  estimated_cost_label     = var.estimated_monthly_cost != null ? format("%.2f", var.estimated_monthly_cost) : "unset"
  container_image_override = var.container_image != null && length(trimspace(var.container_image)) > 0
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

resource "terraform_data" "cost_enforcement" {
  input = var.estimated_monthly_cost

  lifecycle {
    precondition {
      condition     = !var.enforce_cost_controls || (var.estimated_monthly_cost != null && var.estimated_monthly_cost <= local.budget_hard_limit_usd)
      error_message = format("Estimated monthly cost (%s) exceeds the hard limit (%.2f). Run Infracost and set estimated_monthly_cost before deploying.", local.estimated_cost_label, local.budget_hard_limit_usd)
    }
  }
}

module "budget" {
  source = "../../modules/budget"

  budget_name                = "${local.name_prefix}-monthly"
  budget_limit_usd           = var.budget_limit_usd
  warning_threshold_percent  = var.budget_warning_threshold_percent
  critical_threshold_percent = var.budget_hard_limit_percent
  notification_emails        = var.budget_notification_emails
  notification_sns_topic_arn = local.budget_sns_topic_arn
  cost_filters               = local.budget_cost_filters
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix  = local.name_prefix
  service_name = var.service_name
  tags         = local.tags
}

resource "terraform_data" "eks_not_implemented" {
  count = local.platform_is_eks ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.platform != "eks"
      error_message = "platform = \"eks\" is reserved for future use and is not implemented yet."
    }
  }
}

module "network" {
  source = "../../modules/network"

  name_prefix                 = local.name_prefix
  aws_region                  = var.aws_region
  vpc_cidr                    = var.vpc_cidr
  azs                         = local.azs
  public_subnet_cidrs         = var.public_subnet_cidrs
  private_subnet_cidrs        = var.private_subnet_cidrs
  single_nat_gateway          = var.single_nat_gateway
  enable_gateway_endpoints    = var.enable_gateway_endpoints
  enable_interface_endpoints  = var.enable_interface_endpoints
  enable_flow_logs            = var.enable_flow_logs
  flow_logs_retention_in_days = var.flow_logs_retention_in_days
  tags                        = local.tags
}

resource "aws_security_group" "app" {
  count = local.platform_is_ecs ? 1 : 0

  name        = "${local.name_prefix}-app"
  description = "Application compute security group"
  vpc_id      = module.network.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Outbound HTTPS for AWS APIs"
  }

  egress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [module.network.vpc_cidr]
    description = "Database access within VPC"
  }

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-app-sg"
  })
}

resource "aws_security_group_rule" "app_from_alb" {
  count = local.platform_is_ecs ? 1 : 0

  type                     = "ingress"
  from_port                = local.alb_target_port
  to_port                  = local.alb_target_port
  protocol                 = "tcp"
  source_security_group_id = module.alb.alb_security_group_id
  security_group_id        = aws_security_group.app[0].id
  description              = "App traffic from ALB"
}

module "alb" {
  source = "../../modules/alb"

  name_prefix         = local.name_prefix
  vpc_id              = module.network.vpc_id
  vpc_cidr            = module.network.vpc_cidr
  public_subnet_ids   = module.network.public_subnet_ids
  target_port         = local.alb_target_port
  target_type         = local.alb_target_type
  health_check_path   = var.health_check_path
  enable_http         = var.allow_http
  acm_certificate_arn = var.acm_certificate_arn
  ingress_cidrs       = var.alb_ingress_cidrs
  deletion_protection = var.alb_deletion_protection
  enable_access_logs  = var.alb_enable_access_logs
  access_logs_bucket  = var.alb_access_logs_bucket
  enable_waf          = var.alb_enable_waf
  waf_acl_arn         = var.alb_waf_acl_arn
  tags                = local.tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix                     = local.name_prefix
  vpc_id                          = module.network.vpc_id
  private_subnet_ids              = module.network.private_subnet_ids
  app_security_group_id           = local.platform_is_k8s ? module.k8s_ec2_infra[0].worker_security_group_id : local.platform_is_ecs ? aws_security_group.app[0].id : "sg-00000000000000000"
  db_name                         = var.db_name
  db_username                     = var.db_username
  db_port                         = var.db_port
  engine                          = var.db_engine
  engine_version                  = var.db_engine_version
  instance_class                  = var.db_instance_class
  allocated_storage               = var.db_allocated_storage
  max_allocated_storage           = var.db_max_allocated_storage
  storage_type                    = var.db_storage_type
  multi_az                        = var.db_multi_az
  backup_retention_period         = var.db_backup_retention_period
  maintenance_window              = var.db_maintenance_window
  backup_window                   = var.db_backup_window
  deletion_protection             = var.db_deletion_protection
  skip_final_snapshot             = var.db_skip_final_snapshot
  final_snapshot_identifier       = var.db_final_snapshot_identifier
  apply_immediately               = var.db_apply_immediately
  publicly_accessible             = false
  enabled_cloudwatch_logs_exports = var.db_log_exports
  kms_deletion_window_in_days     = var.kms_deletion_window_in_days
  prevent_destroy                 = var.prevent_destroy
  tags                            = local.tags
}

locals {
  container_environment = {
    APP_ENV = var.environment
  }

  container_secrets = {
    DB_SECRET = module.rds.master_user_secret_arn
  }
}

module "ecs" {
  count  = local.platform_is_ecs ? 1 : 0
  source = "../../modules/ecs"

  name_prefix                        = local.name_prefix
  environment                        = var.environment
  private_subnet_ids                 = module.network.private_subnet_ids
  security_group_id                  = aws_security_group.app[0].id
  target_group_arn                   = module.alb.target_group_arn
  capacity_providers                 = local.ecs_capacity_providers
  default_capacity_provider_strategy = local.ecs_default_capacity_provider_strategy
  capacity_provider_strategy         = local.ecs_service_capacity_provider_strategy
  capacity_provider_dependency       = local.ecs_ec2_enabled ? module.ecs_ec2_capacity[0].capacity_provider_name : null
  container_image                    = local.resolved_container_image
  container_port                     = var.container_port
  cpu                                = var.container_cpu
  memory                             = var.container_memory
  requires_compatibilities           = local.ecs_requires_compatibilities
  desired_count                      = var.desired_count
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  environment_variables              = local.container_environment
  container_secrets                  = local.container_secrets
  secrets_arns                       = values(local.container_secrets)
  kms_key_arns                       = [module.rds.kms_key_arn]
  log_retention_in_days              = var.log_retention_in_days
  container_user                     = var.container_user
  readonly_root_filesystem           = var.readonly_root_filesystem
  enable_execute_command             = var.enable_execute_command
  enable_container_insights          = var.enable_container_insights
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  assign_public_ip                   = false
  tags                               = local.tags

  depends_on = [module.alb]
}

module "ecs_ec2_capacity" {
  count  = local.ecs_ec2_enabled ? 1 : 0
  source = "../../modules/ecs-ec2-capacity"

  name_prefix                       = local.name_prefix
  cluster_name                      = local.ecs_cluster_name
  capacity_provider_name            = local.ec2_capacity_provider_name
  private_subnet_ids                = module.network.private_subnet_ids
  security_group_id                 = aws_security_group.app[0].id
  instance_type                     = var.ec2_instance_type
  desired_capacity                  = local.ec2_desired_capacity
  min_size                          = local.ec2_min_size
  max_size                          = local.ec2_max_size
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  ami_id                            = var.ec2_ami_id
  user_data                         = var.ec2_user_data
  enable_ssm                        = var.ec2_enable_ssm
  enable_detailed_monitoring        = var.ec2_enable_detailed_monitoring
  instance_role_policy_arns         = var.ec2_instance_role_policy_arns
  tags                              = local.tags
}

module "k8s_ec2_infra" {
  count  = local.platform_is_k8s ? 1 : 0
  source = "../../modules/k8s-ec2-infra"

  name_prefix                 = local.name_prefix
  cluster_name                = local.k8s_cluster_name
  vpc_id                      = module.network.vpc_id
  vpc_cidr                    = module.network.vpc_cidr
  private_subnet_ids          = module.network.private_subnet_ids
  alb_security_group_id       = module.alb.alb_security_group_id
  alb_target_group_arn        = module.alb.target_group_arn
  control_plane_instance_type = var.k8s_control_plane_instance_type
  worker_instance_type        = var.k8s_worker_instance_type
  worker_desired_capacity     = var.k8s_worker_desired_capacity
  worker_min_size             = var.k8s_worker_min_size
  worker_max_size             = var.k8s_worker_max_size
  ami_id                      = var.k8s_ami_id
  ami_ssm_parameter           = var.k8s_ami_ssm_parameter
  k8s_version                 = var.k8s_version
  pod_cidr                    = var.k8s_pod_cidr
  service_cidr                = var.k8s_service_cidr
  ingress_nodeport            = var.k8s_ingress_nodeport
  enable_ssm                  = var.k8s_enable_ssm
  enable_detailed_monitoring  = var.k8s_enable_detailed_monitoring
  instance_role_policy_arns   = var.k8s_instance_role_policy_arns
  join_parameter_name         = local.k8s_join_parameter_name
  tags                        = local.tags
}

module "observability" {
  source = "../../modules/observability"

  name_prefix             = local.name_prefix
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  rds_instance_id         = module.rds.db_instance_id
  ecs_cluster_name        = local.platform_is_ecs ? module.ecs[0].cluster_name : ""
  ecs_service_name        = local.platform_is_ecs ? module.ecs[0].service_name : ""
  enable_ecs_cpu_alarm    = local.platform_is_ecs
  enable_ec2_cpu_alarm    = local.enable_ec2_cpu_alarm
  ec2_asg_name            = local.ecs_ec2_enabled ? module.ecs_ec2_capacity[0].autoscaling_group_name : local.platform_is_k8s ? module.k8s_ec2_infra[0].worker_autoscaling_group_name : ""
  alarm_sns_topic_arn     = var.alarm_sns_topic_arn
  alb_5xx_threshold       = var.alb_5xx_threshold
  rds_cpu_threshold       = var.rds_cpu_threshold
  ecs_cpu_threshold       = var.ecs_cpu_threshold
  ec2_cpu_threshold       = var.ec2_cpu_threshold
  evaluation_periods      = var.alarm_evaluation_periods
  period_seconds          = var.alarm_period_seconds
  tags                    = local.tags
}
