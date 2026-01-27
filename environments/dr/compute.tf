module "ecr" {
  source = "../../modules/ecr"

  name_prefix                 = local.name_prefix
  service_name                = var.service_name
  enable_replication          = var.ecr_enable_replication
  replication_regions         = var.ecr_replication_regions
  replication_filter_prefixes = var.ecr_replication_filter_prefixes
  tags                        = local.tags
}

module "serverless_api" {
  count  = var.enable_serverless_api ? 1 : 0
  source = "../../modules/apigw-lambda"

  name_prefix           = local.name_prefix
  environment           = var.environment
  vpc_id                = module.network.vpc_id
  vpc_subnet_ids        = module.network.private_subnet_ids
  log_retention_days    = var.serverless_api_log_retention_days
  enable_xray           = var.serverless_api_enable_xray
  cors_allowed_origins  = var.serverless_api_cors_allowed_origins
  additional_route_keys = var.serverless_api_additional_route_keys
  enable_rds_access     = var.serverless_api_enable_rds_access
  rds_security_group_id = var.serverless_api_enable_rds_access ? module.rds.db_security_group_id : null
  rds_secret_arn        = var.serverless_api_rds_secret_arn
  tags                  = local.tags
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
  enable_autoscaling                 = var.enable_autoscaling
  autoscaling_min_capacity           = var.autoscaling_min_capacity
  autoscaling_max_capacity           = var.autoscaling_max_capacity
  autoscaling_target_cpu             = var.autoscaling_target_cpu
  autoscaling_scale_in_cooldown      = var.autoscaling_scale_in_cooldown
  autoscaling_scale_out_cooldown     = var.autoscaling_scale_out_cooldown
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
  log_retention_in_days       = var.log_retention_in_days
  instance_role_policy_arns   = var.k8s_instance_role_policy_arns
  join_parameter_name         = local.k8s_join_parameter_name
  tags                        = local.tags
}

module "eks" {
  count  = local.platform_is_eks ? 1 : 0
  source = "../../modules/eks"

  name_prefix                    = local.name_prefix
  cluster_name                   = local.eks_cluster_name
  cluster_version                = var.eks_cluster_version
  vpc_id                         = module.network.vpc_id
  vpc_cidr                       = module.network.vpc_cidr
  private_subnet_ids             = module.network.private_subnet_ids
  alb_security_group_id          = module.alb.alb_security_group_id
  alb_target_group_arn           = module.alb.target_group_arn
  ingress_nodeport               = var.eks_ingress_nodeport
  node_instance_type             = var.eks_node_instance_type
  node_desired_capacity          = var.eks_node_desired_capacity
  node_min_size                  = var.eks_node_min_size
  node_max_size                  = var.eks_node_max_size
  node_disk_size                 = var.eks_node_disk_size
  node_ami_type                  = var.eks_node_ami_type
  endpoint_public_access         = var.eks_endpoint_public_access
  endpoint_public_access_cidrs   = var.eks_endpoint_public_access_cidrs
  enable_admin_runner            = var.eks_enable_admin_runner
  admin_runner_instance_type     = var.eks_admin_runner_instance_type
  admin_runner_ami_id            = var.eks_admin_runner_ami_id
  admin_runner_ami_ssm_parameter = var.eks_admin_runner_ami_ssm_parameter
  tags                           = local.tags
}
