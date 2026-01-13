output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = local.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = local.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "IDs of NAT gateways."
  value       = aws_nat_gateway.this[*].id
}

output "gateway_endpoint_ids" {
  description = "IDs of gateway VPC endpoints (S3 and DynamoDB)."
  value       = [for endpoint in aws_vpc_endpoint.gateway : endpoint.id]
}

output "flow_logs_log_group_name" {
  description = "CloudWatch log group name for VPC flow logs."
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}
