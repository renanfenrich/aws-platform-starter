mock_provider "aws" {}

run "network_defaults" {
  command = plan

  variables {
    name_prefix          = "test"
    aws_region           = "us-east-1"
    vpc_cidr             = "10.0.0.0/16"
    azs                  = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
    private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
    single_nat_gateway   = true
    enable_flow_logs     = true
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

  override_data {
    target = data.aws_iam_policy_document.flow_logs_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.flow_logs
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "expected two public subnets"
  }

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "expected two private subnets"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "expected a single NAT gateway when single_nat_gateway is true"
  }

  assert {
    condition     = aws_flow_log.this[0].traffic_type == "ALL"
    error_message = "expected flow logs to capture ALL traffic"
  }

  assert {
    condition     = aws_vpc.this.tags["Name"] == "test-vpc"
    error_message = "expected VPC name to use name_prefix"
  }

  assert {
    condition     = aws_vpc.this.tags["Project"] == "test"
    error_message = "expected Project tag on VPC"
  }
}

run "network_invalid_vpc_cidr" {
  command = plan

  variables {
    name_prefix          = "test"
    aws_region           = "us-east-1"
    vpc_cidr             = "invalid"
    azs                  = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
    private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
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

  override_data {
    target = data.aws_iam_policy_document.flow_logs_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.flow_logs
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  expect_failures = [var.vpc_cidr]
}

run "network_invalid_azs" {
  command = plan

  variables {
    name_prefix          = "test"
    aws_region           = "us-east-1"
    vpc_cidr             = "10.0.0.0/16"
    azs                  = ["us-east-1a"]
    public_subnet_cidrs  = ["10.0.0.0/24"]
    private_subnet_cidrs = ["10.0.10.0/24"]
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

  override_data {
    target = data.aws_iam_policy_document.flow_logs_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.flow_logs
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  expect_failures = [var.azs]
}
