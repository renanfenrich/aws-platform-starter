output "alb_5xx_alarm_name" {
  description = "ALB 5xx alarm name."
  value       = aws_cloudwatch_metric_alarm.alb_5xx.alarm_name
}

output "rds_cpu_alarm_name" {
  description = "RDS CPU alarm name."
  value       = aws_cloudwatch_metric_alarm.rds_cpu.alarm_name
}

output "ecs_cpu_alarm_name" {
  description = "ECS CPU alarm name."
  value       = try(aws_cloudwatch_metric_alarm.ecs_cpu[0].alarm_name, null)
}

output "ec2_cpu_alarm_name" {
  description = "EC2 CPU alarm name."
  value       = try(aws_cloudwatch_metric_alarm.ec2_cpu[0].alarm_name, null)
}
