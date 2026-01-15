locals {
  api_name       = "${var.name_prefix}-serverless-api"
  function_name  = "${var.name_prefix}-serverless-api"
  stage_name     = "$default"
  vpc_enabled    = length(var.vpc_subnet_ids) > 0
  route_keys     = distinct(concat(["GET /health", "POST /echo"], var.additional_route_keys))
  lambda_env_set = var.rds_secret_arn != null && length(trimspace(var.rds_secret_arn)) > 0
  lambda_env = var.rds_secret_arn != null && length(trimspace(var.rds_secret_arn)) > 0 ? {
    RDS_SECRET_ARN = var.rds_secret_arn
  } : {}
  access_log_format = jsonencode({
    requestId            = "$context.requestId"
    sourceIp             = "$context.identity.sourceIp"
    requestTime          = "$context.requestTime"
    httpMethod           = "$context.httpMethod"
    routeKey             = "$context.routeKey"
    status               = "$context.status"
    responseLength       = "$context.responseLength"
    integrationError     = "$context.integrationErrorMessage"
    integrationLatencyMs = "$context.integrationLatency"
    responseLatencyMs    = "$context.responseLatency"
    apiId                = "$context.apiId"
    stage                = "$context.stage"
  })
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "api_access" {
  name              = "/aws/apigateway/${local.api_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id

  tags = var.tags
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.root}/.terraform/${local.function_name}.zip"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name_prefix}-serverless-api-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = var.tags
}

locals {
  lambda_security_group_ids = local.vpc_enabled ? concat([aws_security_group.lambda[0].id], var.vpc_security_group_ids) : []
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }

  dynamic "statement" {
    for_each = local.vpc_enabled ? [1] : []

    content {
      actions   = ["ec2:CreateNetworkInterface"]
      resources = ["*"]

      condition {
        test     = "StringEquals"
        variable = "ec2:Subnet"
        values   = var.vpc_subnet_ids
      }

      condition {
        test     = "StringEquals"
        variable = "ec2:SecurityGroup"
        values   = local.lambda_security_group_ids
      }
    }
  }

  dynamic "statement" {
    for_each = local.vpc_enabled ? [1] : []

    content {
      actions = [
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_xray ? [1] : []

    content {
      actions = [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords",
        "xray:GetSamplingRules",
        "xray:GetSamplingTargets",
        "xray:GetSamplingStatisticSummaries"
      ]
      resources = ["*"]
    }
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.name_prefix}-serverless-api-lambda"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_security_group" "lambda" {
  count = local.vpc_enabled ? 1 : 0

  name        = "${var.name_prefix}-serverless-api"
  description = "Lambda security group for serverless API"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-serverless-api-sg"
  })
}

resource "aws_security_group_rule" "lambda_https_egress" {
  count = local.vpc_enabled && !var.enable_rds_access ? 1 : 0

  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda[0].id
  description       = "Outbound HTTPS for AWS APIs"
}

resource "aws_security_group_rule" "lambda_rds_egress" {
  count = local.vpc_enabled && var.enable_rds_access ? 1 : 0

  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.rds_security_group_id
  security_group_id        = aws_security_group.lambda[0].id
  description              = "Outbound Postgres to RDS security group"
}

resource "aws_lambda_function" "this" {
  function_name = local.function_name
  role          = aws_iam_role.lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  timeout     = 10
  memory_size = 128

  dynamic "environment" {
    for_each = local.lambda_env_set ? [1] : []

    content {
      variables = local.lambda_env
    }
  }

  dynamic "vpc_config" {
    for_each = local.vpc_enabled ? [1] : []

    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = local.lambda_security_group_ids
    }
  }

  tracing_config {
    mode = var.enable_xray ? "Active" : "PassThrough"
  }

  tags = var.tags
}

resource "aws_apigatewayv2_api" "this" {
  name          = local.api_name
  protocol_type = "HTTP"
  description   = "Serverless HTTP API for ${var.environment}"

  dynamic "cors_configuration" {
    for_each = length(var.cors_allowed_origins) > 0 ? [1] : []

    content {
      allow_origins = var.cors_allowed_origins
      allow_methods = ["GET", "POST", "OPTIONS"]
      allow_headers = ["content-type", "authorization"]
      max_age       = 300
    }
  }

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.this.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 10000
}

resource "aws_apigatewayv2_route" "this" {
  for_each = { for route in local.route_keys : route => route }

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = local.stage_name
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access.arn
    format          = local.access_log_format
  }

  default_route_settings {
    throttling_burst_limit = var.throttle_burst_limit
    throttling_rate_limit  = var.throttle_rate_limit
  }

  tags = var.tags
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
