output "alb_5xx_alarm_name" {
  description = "ALB 5xx alarm name."
  value       = try(aws_cloudwatch_metric_alarm.alb_5xx[0].alarm_name, null)
}

output "alb_latency_p95_alarm_name" {
  description = "ALB target response time p95 alarm name."
  value       = try(aws_cloudwatch_metric_alarm.alb_latency_p95[0].alarm_name, null)
}

output "alb_unhealthy_hosts_alarm_name" {
  description = "ALB unhealthy host count alarm name."
  value       = try(aws_cloudwatch_metric_alarm.alb_unhealthy_hosts[0].alarm_name, null)
}

output "rds_cpu_alarm_name" {
  description = "RDS CPU alarm name."
  value       = try(aws_cloudwatch_metric_alarm.rds_cpu[0].alarm_name, null)
}

output "rds_free_storage_alarm_name" {
  description = "RDS free storage alarm name."
  value       = try(aws_cloudwatch_metric_alarm.rds_free_storage[0].alarm_name, null)
}

output "ecs_cpu_alarm_name" {
  description = "ECS CPU alarm name."
  value       = try(aws_cloudwatch_metric_alarm.ecs_cpu[0].alarm_name, null)
}

output "ecs_memory_alarm_name" {
  description = "ECS memory alarm name."
  value       = try(aws_cloudwatch_metric_alarm.ecs_memory[0].alarm_name, null)
}

output "ecs_capacity_alarm_name" {
  description = "ECS desired vs running alarm name."
  value       = try(aws_cloudwatch_metric_alarm.ecs_capacity[0].alarm_name, null)
}

output "ec2_cpu_alarm_name" {
  description = "EC2 CPU alarm name."
  value       = try(aws_cloudwatch_metric_alarm.ec2_cpu[0].alarm_name, null)
}

output "dashboard_name" {
  description = "CloudWatch dashboard name."
  value       = aws_cloudwatch_dashboard.observability.dashboard_name
}
