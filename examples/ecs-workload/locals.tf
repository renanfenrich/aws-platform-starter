locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  state_key    = length(trimspace(var.state_key)) > 0 ? var.state_key : "${var.project_name}/${var.environment}/terraform.tfstate"
  state_region = length(trimspace(var.state_region)) > 0 ? var.state_region : var.aws_region

  container_port   = data.aws_lb_target_group.platform.port
  health_check_path = data.aws_lb_target_group.platform.health_check[0].path
  container_image  = "${data.terraform_remote_state.platform.outputs.ecr_repository_url}:${var.image_tag}"

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

  environment_variables = {
    APP_ENV              = var.environment
    SERVICE_NAME         = var.service_name
    ALB_HEALTHCHECK_PATH = local.health_check_path
  }

  container_secrets = {
    DB_SECRET = data.terraform_remote_state.platform.outputs.rds_master_secret_arn
  }

  environment_list = [for key, value in local.environment_variables : { name = key, value = value }]
  secrets_list     = [for key, value in local.container_secrets : { name = key, valueFrom = value }]

  alb_https_listener_arn = data.terraform_remote_state.platform.outputs.alb_https_listener_arn
  alb_http_listener_arn  = data.terraform_remote_state.platform.outputs.alb_http_listener_arn
  alb_listener_arn       = coalesce(local.alb_https_listener_arn, local.alb_http_listener_arn)
}
