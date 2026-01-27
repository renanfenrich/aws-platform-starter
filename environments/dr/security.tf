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

  name_prefix           = local.name_prefix
  vpc_id                = module.network.vpc_id
  vpc_cidr              = module.network.vpc_cidr
  public_subnet_ids     = module.network.public_subnet_ids
  target_port           = local.alb_target_port
  target_type           = local.alb_target_type
  health_check_path     = var.health_check_path
  enable_public_ingress = var.alb_enable_public_ingress
  enable_http           = var.allow_http
  acm_certificate_arn   = var.acm_certificate_arn
  ingress_cidrs         = var.alb_ingress_cidrs
  deletion_protection   = var.alb_deletion_protection
  enable_access_logs    = var.alb_enable_access_logs
  access_logs_bucket    = var.alb_access_logs_bucket
  enable_waf            = var.alb_enable_waf
  waf_acl_arn           = var.alb_waf_acl_arn
  tags                  = local.tags
}
