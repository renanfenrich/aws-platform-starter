mock_provider "aws" {}

run "apigw_lambda_vpc" {
  command = plan

  variables {
    name_prefix        = "test"
    environment        = "dev"
    vpc_id             = "vpc-12345678"
    vpc_subnet_ids     = ["subnet-123", "subnet-456"]
    log_retention_days = 7
    tags = {
      Project     = "test"
      Environment = "dev"
      Service     = "test"
      Owner       = "test"
      CostCenter  = "test"
      ManagedBy   = "Terraform"
      Repository  = "aws-platform-starter"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.lambda_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.lambda_policy
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = aws_apigatewayv2_api.this.protocol_type == "HTTP"
    error_message = "expected HTTP API Gateway protocol"
  }

  assert {
    condition     = length(aws_apigatewayv2_stage.this.access_log_settings) == 1
    error_message = "expected API access logs to be enabled"
  }

  assert {
    condition     = aws_cloudwatch_log_group.api_access.retention_in_days == 7
    error_message = "expected API access log retention to match input"
  }

  assert {
    condition     = aws_cloudwatch_log_group.lambda.retention_in_days == 7
    error_message = "expected Lambda log retention to match input"
  }

  assert {
    condition     = aws_lambda_permission.apigw.principal == "apigateway.amazonaws.com"
    error_message = "expected API Gateway to be allowed to invoke Lambda"
  }

  assert {
    condition     = length(aws_lambda_function.this.vpc_config) == 1
    error_message = "expected Lambda VPC config to be set"
  }

  assert {
    condition     = toset(aws_lambda_function.this.vpc_config[0].subnet_ids) == toset(["subnet-123", "subnet-456"])
    error_message = "expected Lambda to use the provided private subnets"
  }

  assert {
    condition     = length(aws_lambda_function.this.vpc_config[0].security_group_ids) == 1
    error_message = "expected Lambda to attach the dedicated security group"
  }

  assert {
    condition     = aws_security_group.lambda[0].tags["Name"] == "test-serverless-api-sg"
    error_message = "expected Lambda security group Name tag to include name_prefix"
  }

  assert {
    condition     = length(aws_apigatewayv2_route.this) == 2
    error_message = "expected default /health and /echo routes"
  }

  assert {
    condition     = aws_apigatewayv2_stage.this.default_route_settings[0].throttling_rate_limit == 25
    error_message = "expected default throttle rate limit"
  }
}

run "apigw_lambda_rds_access" {
  command = plan

  variables {
    name_prefix           = "test"
    environment           = "dev"
    vpc_id                = "vpc-12345678"
    vpc_subnet_ids        = ["subnet-123", "subnet-456"]
    enable_rds_access     = true
    rds_security_group_id = "sg-rds12345"
    enable_xray           = true
    additional_route_keys = ["GET /info"]
    log_retention_days    = 14
    throttle_burst_limit  = 100
    throttle_rate_limit   = 50
    cors_allowed_origins  = ["https://example.com"]
    tags = {
      Project     = "test"
      Environment = "dev"
      Service     = "test"
      Owner       = "test"
      CostCenter  = "test"
      ManagedBy   = "Terraform"
      Repository  = "aws-platform-starter"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.lambda_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.lambda_policy
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition     = length(aws_security_group_rule.lambda_rds_egress) == 1
    error_message = "expected RDS egress rule when enable_rds_access is true"
  }

  assert {
    condition     = aws_security_group_rule.lambda_rds_egress[0].from_port == 5432
    error_message = "expected RDS egress rule to use port 5432"
  }

  assert {
    condition     = aws_security_group_rule.lambda_rds_egress[0].source_security_group_id == "sg-rds12345"
    error_message = "expected RDS egress to target the provided security group"
  }

  assert {
    condition     = length(aws_security_group_rule.lambda_https_egress) == 0
    error_message = "expected HTTPS egress rule to be disabled when RDS access is enabled"
  }

  assert {
    condition     = aws_lambda_function.this.tracing_config[0].mode == "Active"
    error_message = "expected X-Ray tracing to be enabled"
  }

  assert {
    condition     = length(aws_apigatewayv2_route.this) == 3
    error_message = "expected additional route to be configured"
  }
}
