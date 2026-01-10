terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "ecs_capacity_mode" {
  type        = string
  description = "ECS capacity mode to test (fargate, fargate_spot, or ec2)."
  default     = "fargate"
}

variable "platform" {
  type        = string
  description = "Platform selection (ecs or k8s_self_managed)."
  default     = "ecs"
}

locals {
  target_group_arn           = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/1234567890abcdef"
  alb_security_group_id      = "sg-0123456789abcdef0"
  platform_is_ecs            = var.platform == "ecs"
  platform_is_k8s            = var.platform == "k8s_self_managed"
  ecs_cluster_name           = "test-ecs"
  ec2_capacity_provider_name = "test-ecs-ec2"
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
  k8s_cluster_name                       = "test-k8s"
}

module "network" {
  source = "../../modules/network"

  name_prefix          = "test"
  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  single_nat_gateway   = true
  enable_flow_logs     = false
  tags = {
    Project     = "test"
    Environment = "test"
    Service     = "test"
    Owner       = "test"
    CostCenter  = "test"
    ManagedBy   = "Terraform"
    Repository  = "aws-platform-starter"
  }
}

resource "aws_security_group" "app" {
  name        = "test-app-sg"
  description = "Test app security group"
  vpc_id      = module.network.vpc_id
}

module "ecs" {
  count  = local.platform_is_ecs ? 1 : 0
  source = "../../modules/ecs"

  name_prefix                        = "test"
  environment                        = "test"
  private_subnet_ids                 = module.network.private_subnet_ids
  security_group_id                  = aws_security_group.app.id
  target_group_arn                   = local.target_group_arn
  capacity_providers                 = local.ecs_capacity_providers
  default_capacity_provider_strategy = local.ecs_default_capacity_provider_strategy
  capacity_provider_strategy         = local.ecs_service_capacity_provider_strategy
  capacity_provider_dependency       = local.ecs_ec2_enabled ? module.ecs_ec2_capacity[0].capacity_provider_name : null
  container_image                    = "public.ecr.aws/nginx/nginx:latest"
  container_port                     = 80
  enable_execute_command             = false
  requires_compatibilities           = local.ecs_requires_compatibilities
  tags = {
    Project     = "test"
    Environment = "test"
    Service     = "test"
    Owner       = "test"
    CostCenter  = "test"
    ManagedBy   = "Terraform"
    Repository  = "aws-platform-starter"
  }
}

module "ecs_ec2_capacity" {
  count  = local.ecs_ec2_enabled ? 1 : 0
  source = "../../modules/ecs-ec2-capacity"

  name_prefix                = "test"
  cluster_name               = local.ecs_cluster_name
  capacity_provider_name     = local.ec2_capacity_provider_name
  private_subnet_ids         = module.network.private_subnet_ids
  security_group_id          = aws_security_group.app.id
  instance_type              = "t3.micro"
  desired_capacity           = 1
  min_size                   = 1
  max_size                   = 1
  enable_detailed_monitoring = false
  tags = {
    Project     = "test"
    Environment = "test"
    Service     = "test"
    Owner       = "test"
    CostCenter  = "test"
    ManagedBy   = "Terraform"
    Repository  = "aws-platform-starter"
  }
}

module "k8s_ec2_infra" {
  count  = local.platform_is_k8s ? 1 : 0
  source = "../../modules/k8s-ec2-infra"

  name_prefix                 = "test"
  cluster_name                = local.k8s_cluster_name
  vpc_id                      = module.network.vpc_id
  vpc_cidr                    = module.network.vpc_cidr
  private_subnet_ids          = module.network.private_subnet_ids
  alb_security_group_id       = local.alb_security_group_id
  alb_target_group_arn        = local.target_group_arn
  control_plane_instance_type = "t3.small"
  worker_instance_type        = "t3.small"
  worker_desired_capacity     = 1
  worker_min_size             = 1
  worker_max_size             = 1
  ami_id                      = "ami-1234567890abcdef0"
  enable_detailed_monitoring  = false
  tags = {
    Project     = "test"
    Environment = "test"
    Service     = "test"
    Owner       = "test"
    CostCenter  = "test"
    ManagedBy   = "Terraform"
    Repository  = "aws-platform-starter"
  }
}
