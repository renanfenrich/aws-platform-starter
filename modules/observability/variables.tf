variable "name_prefix" {
  type        = string
  description = "Prefix used for naming alarms."
}

variable "compute_mode" {
  type        = string
  description = "Compute mode for alarms (ecs or ec2)."
  default     = "ecs"

  validation {
    condition     = contains(["ecs", "ec2"], var.compute_mode)
    error_message = "compute_mode must be ecs or ec2."
  }

  validation {
    condition     = var.compute_mode != "ecs" || (length(trim(var.ecs_cluster_name)) > 0 && length(trim(var.ecs_service_name)) > 0)
    error_message = "ecs_cluster_name and ecs_service_name are required when compute_mode is ecs."
  }

  validation {
    condition     = var.compute_mode != "ec2" || length(trim(var.ec2_asg_name)) > 0
    error_message = "ec2_asg_name is required when compute_mode is ec2."
  }
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
  description = "ECS cluster name (required when compute_mode is ecs)."
  default     = ""
}

variable "ecs_service_name" {
  type        = string
  description = "ECS service name (required when compute_mode is ecs)."
  default     = ""
}

variable "ec2_asg_name" {
  type        = string
  description = "EC2 Auto Scaling group name (required when compute_mode is ec2)."
  default     = ""
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

variable "ec2_cpu_threshold" {
  type        = number
  description = "Threshold for EC2 CPU utilization."
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
