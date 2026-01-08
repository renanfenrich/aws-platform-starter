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

variable "compute_mode" {
  type        = string
  description = "Compute mode to test (ecs or ec2)."
  default     = "ecs"
}

locals {
  target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/1234567890abcdef"
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
  count  = var.compute_mode == "ecs" ? 1 : 0
  source = "../../modules/ecs"

  name_prefix            = "test"
  environment            = "test"
  private_subnet_ids     = module.network.private_subnet_ids
  security_group_id      = aws_security_group.app.id
  target_group_arn       = local.target_group_arn
  container_image        = "public.ecr.aws/nginx/nginx:latest"
  container_port         = 80
  enable_execute_command = false
  tags = {
    Environment = "test"
  }
}

module "ec2_service" {
  count  = var.compute_mode == "ec2" ? 1 : 0
  source = "../../modules/ec2-service"

  name_prefix        = "test"
  private_subnet_ids = module.network.private_subnet_ids
  security_group_id  = aws_security_group.app.id
  target_group_arn   = local.target_group_arn
  ami_id             = "ami-1234567890abcdef0"
  instance_type      = "t3.micro"
  desired_capacity   = 1
  min_size           = 1
  max_size           = 1
  tags = {
    Environment = "test"
  }
}
