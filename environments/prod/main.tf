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

locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  azs          = slice(data.aws_availability_zones.available.names, 0, 2)
  ec2_min_size = var.ec2_min_size != null ? var.ec2_min_size : var.desired_count
  ec2_max_size = var.ec2_max_size != null ? var.ec2_max_size : var.desired_count
  tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "aws-production-platform-terraform"
    },
    var.additional_tags
  )
}

module "network" {
  source = "../../modules/network"

  name_prefix                 = local.name_prefix
  vpc_cidr                    = var.vpc_cidr
  azs                         = local.azs
  public_subnet_cidrs         = var.public_subnet_cidrs
  private_subnet_cidrs        = var.private_subnet_cidrs
  single_nat_gateway          = var.single_nat_gateway
  enable_flow_logs            = var.enable_flow_logs
  flow_logs_retention_in_days = var.flow_logs_retention_in_days
  tags                        = local.tags
}

resource "aws_security_group" "app" {
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
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = module.alb.alb_security_group_id
  security_group_id        = aws_security_group.app.id
  description              = "App traffic from ALB"
}

module "alb" {
  source = "../../modules/alb"

  name_prefix         = local.name_prefix
  vpc_id              = module.network.vpc_id
  vpc_cidr            = module.network.vpc_cidr
  public_subnet_ids   = module.network.public_subnet_ids
  target_port         = var.container_port
  target_type         = var.compute_mode == "ecs" ? "ip" : "instance"
  health_check_path   = var.health_check_path
  enable_http         = var.allow_http
  acm_certificate_arn = var.acm_certificate_arn
  ingress_cidrs       = var.alb_ingress_cidrs
  deletion_protection = var.alb_deletion_protection
  tags                = local.tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix                     = local.name_prefix
  vpc_id                          = module.network.vpc_id
  private_subnet_ids              = module.network.private_subnet_ids
  app_security_group_id           = aws_security_group.app.id
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
  count  = var.compute_mode == "ecs" ? 1 : 0
  source = "../../modules/ecs"

  name_prefix                        = local.name_prefix
  environment                        = var.environment
  private_subnet_ids                 = module.network.private_subnet_ids
  security_group_id                  = aws_security_group.app.id
  target_group_arn                   = module.alb.target_group_arn
  container_image                    = var.container_image
  container_port                     = var.container_port
  cpu                                = var.container_cpu
  memory                             = var.container_memory
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

module "ec2_service" {
  count  = var.compute_mode == "ec2" ? 1 : 0
  source = "../../modules/ec2-service"

  name_prefix                       = local.name_prefix
  private_subnet_ids                = module.network.private_subnet_ids
  security_group_id                 = aws_security_group.app.id
  target_group_arn                  = module.alb.target_group_arn
  instance_type                     = var.ec2_instance_type
  desired_capacity                  = var.desired_count
  min_size                          = local.ec2_min_size
  max_size                          = local.ec2_max_size
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  ami_id                            = var.ec2_ami_id
  user_data                         = var.ec2_user_data
  secrets_arns                      = values(local.container_secrets)
  kms_key_arns                      = [module.rds.kms_key_arn]
  log_retention_in_days             = var.log_retention_in_days
  instance_role_policy_arns         = var.ec2_instance_role_policy_arns
  tags                              = local.tags

  depends_on = [module.alb]
}

module "observability" {
  source = "../../modules/observability"

  name_prefix             = local.name_prefix
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  rds_instance_id         = module.rds.db_instance_id
  compute_mode            = var.compute_mode
  ecs_cluster_name        = var.compute_mode == "ecs" ? module.ecs[0].cluster_name : ""
  ecs_service_name        = var.compute_mode == "ecs" ? module.ecs[0].service_name : ""
  ec2_asg_name            = var.compute_mode == "ec2" ? module.ec2_service[0].autoscaling_group_name : ""
  alarm_sns_topic_arn     = var.alarm_sns_topic_arn
  alb_5xx_threshold       = var.alb_5xx_threshold
  rds_cpu_threshold       = var.rds_cpu_threshold
  ecs_cpu_threshold       = var.ecs_cpu_threshold
  ec2_cpu_threshold       = var.ec2_cpu_threshold
  evaluation_periods      = var.alarm_evaluation_periods
  period_seconds          = var.alarm_period_seconds
  tags                    = local.tags
}
