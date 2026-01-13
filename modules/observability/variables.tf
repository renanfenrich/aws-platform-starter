variable "name_prefix" {
  type        = string
  description = "Prefix used for naming alarms."
}

variable "enable_alarms" {
  type        = bool
  description = "Enable CloudWatch alarms for this environment."
  default     = true
}

variable "enable_ec2_cpu_alarm" {
  type        = bool
  description = "Enable EC2 CPU alarm for EC2-based compute."
  default     = false
}

variable "enable_ecs_cpu_alarm" {
  type        = bool
  description = "Enable ECS service alarms (CPU, memory, capacity)."
  default     = true
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
  description = "ECS cluster name for ECS service alarms."
  default     = ""

  validation {
    condition     = !var.enable_ecs_cpu_alarm || length(trimspace(var.ecs_cluster_name)) > 0
    error_message = "ecs_cluster_name is required when enable_ecs_cpu_alarm is true."
  }
}

variable "ecs_service_name" {
  type        = string
  description = "ECS service name for ECS service alarms."
  default     = ""

  validation {
    condition     = !var.enable_ecs_cpu_alarm || length(trimspace(var.ecs_service_name)) > 0
    error_message = "ecs_service_name is required when enable_ecs_cpu_alarm is true."
  }
}

variable "ec2_asg_name" {
  type        = string
  description = "EC2 Auto Scaling group name for capacity provider alarms."
  default     = ""

  validation {
    condition     = !var.enable_ec2_cpu_alarm || length(trimspace(var.ec2_asg_name)) > 0
    error_message = "ec2_asg_name is required when enable_ec2_cpu_alarm is true."
  }
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

variable "alb_latency_p95_threshold" {
  type        = number
  description = "Threshold in seconds for ALB target response time p95."
  default     = 1
}

variable "alb_unhealthy_host_threshold" {
  type        = number
  description = "Threshold for ALB unhealthy host count."
  default     = 1
}

variable "rds_cpu_threshold" {
  type        = number
  description = "Threshold for RDS CPU utilization."
  default     = 80
}

variable "rds_free_storage_threshold_gb" {
  type        = number
  description = "Threshold in GiB for RDS free storage space."
  default     = 5
}

variable "ecs_cpu_threshold" {
  type        = number
  description = "Threshold for ECS CPU utilization."
  default     = 80
}

variable "ecs_memory_threshold" {
  type        = number
  description = "Threshold for ECS memory utilization."
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

  validation {
    condition = alltrue([
      for key in ["Project", "Environment", "Service", "Owner", "CostCenter", "ManagedBy", "Repository"] :
      contains(keys(var.tags), key) && length(trimspace(var.tags[key])) > 0
    ])
    error_message = "tags must include non-empty Project, Environment, Service, Owner, CostCenter, ManagedBy, and Repository values."
  }
}
