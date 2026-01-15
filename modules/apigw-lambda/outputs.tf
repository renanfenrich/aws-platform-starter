output "api_endpoint" {
  description = "API Gateway invoke URL."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "api_id" {
  description = "API Gateway ID."
  value       = aws_apigatewayv2_api.this.id
}

output "stage_name" {
  description = "API Gateway stage name."
  value       = aws_apigatewayv2_stage.this.name
}

output "lambda_function_name" {
  description = "Lambda function name."
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN."
  value       = aws_lambda_function.this.arn
}

output "lambda_security_group_id" {
  description = "Security group ID for the Lambda function (null when VPC is disabled)."
  value       = local.vpc_enabled ? aws_security_group.lambda[0].id : null
}
