variable "name_prefix" {
  type        = string
  description = "Prefix used for naming alarms."
}

variable "alb_arn_suffix" {
  type        = string
  description = "ARN suffix of the ALB."
}

variable "target_group_arn_suffix" {
  type        = string
  description = "ARN suffix of the target group."
}

variable "rds_instance_id" {
  type        = string
  description = "RDS instance identifier."
}

variable "ecs_cluster_name" {
  type        = string
  description = "ECS cluster name."
}

variable "ecs_service_name" {
  type        = string
  description = "ECS service name."
}

variable "alarm_sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for alarm notifications (optional)."
  default     = ""
}

variable "alb_5xx_threshold" {
  type        = number
  description = "Threshold for ALB 5xx target errors."
  default     = 5
}

variable "rds_cpu_threshold" {
  type        = number
  description = "Threshold for RDS CPU utilization."
  default     = 80
}

variable "ecs_cpu_threshold" {
  type        = number
  description = "Threshold for ECS CPU utilization."
  default     = 80
}

variable "evaluation_periods" {
  type        = number
  description = "Number of periods for alarm evaluation."
  default     = 2
}

variable "period_seconds" {
  type        = number
  description = "Metric evaluation period in seconds."
  default     = 60
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to alarm resources."
  default     = {}
}
