mock_provider "aws" {}

run "alb_http_enabled" {
  command = plan

  variables {
    name_prefix           = "test"
    vpc_id                = "vpc-12345678"
    vpc_cidr              = "10.0.0.0/16"
    public_subnet_ids     = ["subnet-123", "subnet-456"]
    target_port           = 80
    health_check_path     = "/health"
    enable_public_ingress = true
    enable_http           = true
    acm_certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    ingress_cidrs         = ["0.0.0.0/0"]
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

  assert {
    condition     = aws_lb_listener.https[0].port == 443 && aws_lb_listener.https[0].protocol == "HTTPS"
    error_message = "expected HTTPS listener on port 443"
  }

  assert {
    condition     = aws_lb_listener.https[0].certificate_arn == "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    error_message = "expected HTTPS listener to use the provided ACM certificate"
  }

  assert {
    condition     = length(aws_lb_listener.http) == 1 && aws_lb_listener.http[0].port == 80 && aws_lb_listener.http[0].protocol == "HTTP"
    error_message = "expected HTTP listener on port 80 when enable_http is true"
  }

  assert {
    condition     = toset(aws_lb.this.subnets) == toset(["subnet-123", "subnet-456"])
    error_message = "expected ALB to use the provided public subnets"
  }

  assert {
    condition     = aws_security_group_rule.alb_https_ingress[0].from_port == 443 && toset(aws_security_group_rule.alb_https_ingress[0].cidr_blocks) == toset(["0.0.0.0/0"])
    error_message = "expected HTTPS ingress from 0.0.0.0/0"
  }

  assert {
    condition     = length(aws_security_group_rule.alb_http_ingress) == 1 && aws_security_group_rule.alb_http_ingress[0].from_port == 80 && toset(aws_security_group_rule.alb_http_ingress[0].cidr_blocks) == toset(["0.0.0.0/0"])
    error_message = "expected HTTP ingress on port 80 when enable_http is true"
  }

  assert {
    condition     = aws_lb_listener.https[0].default_action[0].type == "forward"
    error_message = "expected HTTPS listener default action to forward"
  }

  assert {
    condition     = aws_lb_listener.http[0].default_action[0].type == "forward"
    error_message = "expected HTTP listener default action to forward"
  }

  assert {
    condition     = aws_lb_target_group.this.port == 80 && aws_lb_target_group.this.protocol == "HTTP"
    error_message = "expected target group to use the configured port and HTTP protocol"
  }

  assert {
    condition     = aws_lb_target_group.this.health_check[0].path == "/health"
    error_message = "expected health check path to use the configured value"
  }

  assert {
    condition     = aws_lb.this.tags["Project"] == "test"
    error_message = "expected Project tag on ALB"
  }

  assert {
    condition     = aws_lb.this.tags["Name"] == "test-alb"
    error_message = "expected Name tag on ALB to use name_prefix"
  }
}

run "alb_http_disabled" {
  command = plan

  variables {
    name_prefix           = "test"
    vpc_id                = "vpc-12345678"
    vpc_cidr              = "10.0.0.0/16"
    public_subnet_ids     = ["subnet-123", "subnet-456"]
    target_port           = 80
    enable_public_ingress = true
    enable_http           = false
    acm_certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    ingress_cidrs         = ["0.0.0.0/0"]
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

  assert {
    condition     = length(aws_lb_listener.http) == 0
    error_message = "expected no HTTP listener when enable_http is false"
  }

  assert {
    condition     = length(aws_security_group_rule.alb_http_ingress) == 0
    error_message = "expected no HTTP ingress rule when enable_http is false"
  }

  assert {
    condition     = aws_lb_listener.https[0].port == 443 && aws_lb_listener.https[0].certificate_arn == "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    error_message = "expected HTTPS listener to remain configured"
  }
}

run "alb_public_ingress_disabled" {
  command = plan

  variables {
    name_prefix           = "test"
    vpc_id                = "vpc-12345678"
    vpc_cidr              = "10.0.0.0/16"
    public_subnet_ids     = ["subnet-123", "subnet-456"]
    target_port           = 80
    enable_public_ingress = false
    enable_http           = false
    acm_certificate_arn   = ""
    ingress_cidrs         = ["0.0.0.0/0"]
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

  assert {
    condition     = length(aws_lb_listener.https) == 0
    error_message = "expected no HTTPS listener when public ingress is disabled"
  }

  assert {
    condition     = length(aws_security_group_rule.alb_https_ingress) == 0
    error_message = "expected no HTTPS ingress rule when public ingress is disabled"
  }

  assert {
    condition     = length(aws_lb_listener.http) == 0
    error_message = "expected no HTTP listener when public ingress is disabled"
  }
}

run "alb_missing_acm_certificate" {
  command = plan

  variables {
    name_prefix           = "test"
    vpc_id                = "vpc-12345678"
    vpc_cidr              = "10.0.0.0/16"
    public_subnet_ids     = ["subnet-123", "subnet-456"]
    target_port           = 80
    enable_http           = false
    enable_public_ingress = true
    acm_certificate_arn   = ""
    ingress_cidrs         = ["0.0.0.0/0"]
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

  expect_failures = [var.acm_certificate_arn]
}
