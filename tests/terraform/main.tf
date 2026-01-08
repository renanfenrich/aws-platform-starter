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

locals {
  target_group_arn           = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/1234567890abcdef"
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
    Environment = "test"
  }
}

resource "aws_security_group" "app" {
  name        = "test-app-sg"
  description = "Test app security group"
  vpc_id      = module.network.vpc_id
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix                        = "test"
  environment                        = "test"
  private_subnet_ids                 = module.network.private_subnet_ids
  security_group_id                  = aws_security_group.app.id
  target_group_arn                   = local.target_group_arn
  capacity_providers                 = local.ecs_capacity_providers
  default_capacity_provider_strategy = local.ecs_default_capacity_provider_strategy
  capacity_provider_strategy         = local.ecs_service_capacity_provider_strategy
  capacity_provider_dependency       = var.ecs_capacity_mode == "ec2" ? module.ecs_ec2_capacity[0].capacity_provider_name : null
  container_image                    = "public.ecr.aws/nginx/nginx:latest"
  container_port                     = 80
  enable_execute_command             = false
  requires_compatibilities           = local.ecs_requires_compatibilities
  tags = {
    Environment = "test"
  }
}

module "ecs_ec2_capacity" {
  count  = var.ecs_capacity_mode == "ec2" ? 1 : 0
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
    Environment = "test"
  }
}
