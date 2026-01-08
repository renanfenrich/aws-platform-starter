variable "project_name" {
  type        = string
  description = "Project name used for resource naming."
}

variable "environment" {
  type        = string
  description = "Environment name (dev or prod)."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "ecs_capacity_mode" {
  type        = string
  description = "ECS capacity mode (fargate, fargate_spot, or ec2)."
  default     = "fargate"

  validation {
    condition     = contains(["fargate", "fargate_spot", "ec2"], var.ecs_capacity_mode)
    error_message = "ecs_capacity_mode must be fargate, fargate_spot, or ec2."
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy into."
}

variable "allowed_account_ids" {
  type        = list(string)
  description = "Optional list of AWS account IDs allowed to run this config."
  default     = []
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs (2 subnets)."

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "public_subnet_cidrs must contain two CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs (2 subnets)."

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "private_subnet_cidrs must contain two CIDR blocks."
  }
}

variable "single_nat_gateway" {
  type        = bool
  description = "Use a single NAT gateway to reduce cost."
  default     = true
}

variable "enable_flow_logs" {
  type        = bool
  description = "Enable VPC flow logs."
  default     = true
}

variable "flow_logs_retention_in_days" {
  type        = number
  description = "Retention period for VPC flow logs."
  default     = 30
}

variable "allow_http" {
  type        = bool
  description = "Allow HTTP listener (dev only)."
  default     = false

  validation {
    condition     = !(var.allow_http && var.environment == "prod")
    error_message = "allow_http must be false in prod."
  }
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS."
}

variable "alb_ingress_cidrs" {
  type        = list(string)
  description = "Allowed CIDR ranges for ALB ingress."
  default     = ["0.0.0.0/0"]
}

variable "alb_deletion_protection" {
  type        = bool
  description = "Enable ALB deletion protection."
  default     = true
}

variable "container_image" {
  type        = string
  description = "Container image to deploy."
}

variable "container_port" {
  type        = number
  description = "Container port exposed by the application."
}

variable "container_cpu" {
  type        = number
  description = "CPU units for the task."
  default     = 256
}

variable "container_memory" {
  type        = number
  description = "Memory (MiB) for the task."
  default     = 512
}

variable "desired_count" {
  type        = number
  description = "Desired number of ECS tasks."
  default     = 1
}

variable "health_check_path" {
  type        = string
  description = "Health check path for the ALB target group."
  default     = "/"
}

variable "health_check_grace_period_seconds" {
  type        = number
  description = "Grace period before ALB health checks start."
  default     = 60
}

variable "container_user" {
  type        = string
  description = "User ID for the container process."
  default     = "1000"
}

variable "readonly_root_filesystem" {
  type        = bool
  description = "Run containers with a read-only root filesystem."
  default     = false
}

variable "enable_execute_command" {
  type        = bool
  description = "Enable ECS Exec for troubleshooting."
  default     = true
}

variable "enable_container_insights" {
  type        = bool
  description = "Enable ECS container insights."
  default     = true
}

variable "deployment_minimum_healthy_percent" {
  type        = number
  description = "Minimum healthy percent during deployments."
  default     = 50
}

variable "deployment_maximum_percent" {
  type        = number
  description = "Maximum percent during deployments."
  default     = 200
}

variable "log_retention_in_days" {
  type        = number
  description = "Retention for compute logs."
  default     = 30
}

variable "ec2_instance_type" {
  type        = string
  description = "EC2 instance type for ECS capacity provider instances."
  default     = "t3.micro"
}

variable "ec2_desired_capacity" {
  type        = number
  description = "Desired capacity for the ECS EC2 Auto Scaling group."
  default     = null
}

variable "ec2_min_size" {
  type        = number
  description = "Minimum EC2 instances for the ECS capacity provider Auto Scaling group."
  default     = null
}

variable "ec2_max_size" {
  type        = number
  description = "Maximum EC2 instances for the ECS capacity provider Auto Scaling group."
  default     = null
}

variable "ec2_ami_id" {
  type        = string
  description = "Optional AMI ID override for ECS-optimized instances."
  default     = null
}

variable "ec2_user_data" {
  type        = string
  description = "Optional user data appended to the ECS instance bootstrap."
  default     = ""
}

variable "ec2_enable_ssm" {
  type        = bool
  description = "Attach SSM permissions for ECS EC2 instances."
  default     = true
}

variable "ec2_enable_detailed_monitoring" {
  type        = bool
  description = "Enable detailed monitoring for ECS EC2 instances."
  default     = true
}

variable "ec2_instance_role_policy_arns" {
  type        = list(string)
  description = "Additional policy ARNs to attach to the ECS EC2 instance role."
  default     = []
}

variable "db_name" {
  type        = string
  description = "Database name."
}

variable "db_username" {
  type        = string
  description = "Database master username."
}

variable "db_port" {
  type        = number
  description = "Database port."
  default     = 5432
}

variable "db_engine" {
  type        = string
  description = "Database engine."
  default     = "postgres"
}

variable "db_engine_version" {
  type        = string
  description = "Database engine version."
  default     = "15.4"
}

variable "db_instance_class" {
  type        = string
  description = "Database instance class."
}

variable "db_allocated_storage" {
  type        = number
  description = "Allocated storage (GB)."
  default     = 20
}

variable "db_max_allocated_storage" {
  type        = number
  description = "Max storage (GB)."
  default     = 100
}

variable "db_storage_type" {
  type        = string
  description = "Storage type."
  default     = "gp3"
}

variable "db_multi_az" {
  type        = bool
  description = "Enable Multi-AZ for RDS."
  default     = false
}

variable "db_backup_retention_period" {
  type        = number
  description = "Backup retention period in days."
  default     = 3
}

variable "db_maintenance_window" {
  type        = string
  description = "RDS maintenance window."
  default     = "Mon:00:00-Mon:03:00"
}

variable "db_backup_window" {
  type        = string
  description = "RDS backup window."
  default     = "03:00-04:00"
}

variable "db_deletion_protection" {
  type        = bool
  description = "Enable RDS deletion protection."
  default     = false
}

variable "db_skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on delete."
  default     = true
}

variable "db_final_snapshot_identifier" {
  type        = string
  description = "Final snapshot identifier when skip_final_snapshot is false."
  default     = null
}

variable "db_apply_immediately" {
  type        = bool
  description = "Apply RDS changes immediately."
  default     = true
}

variable "db_log_exports" {
  type        = list(string)
  description = "RDS log exports to CloudWatch."
  default     = ["postgresql"]
}

variable "kms_deletion_window_in_days" {
  type        = number
  description = "KMS deletion window."
  default     = 30
}

variable "prevent_destroy" {
  type        = bool
  description = "Prevent destroying critical resources."
  default     = false
}

variable "alarm_sns_topic_arn" {
  type        = string
  description = "SNS topic for alarm notifications."
  default     = ""
}

variable "alb_5xx_threshold" {
  type        = number
  description = "ALB 5xx alarm threshold."
  default     = 5
}

variable "rds_cpu_threshold" {
  type        = number
  description = "RDS CPU alarm threshold."
  default     = 80
}

variable "ecs_cpu_threshold" {
  type        = number
  description = "ECS CPU alarm threshold."
  default     = 80
}

variable "ec2_cpu_threshold" {
  type        = number
  description = "EC2 capacity provider CPU alarm threshold."
  default     = 80
}

variable "alarm_evaluation_periods" {
  type        = number
  description = "Alarm evaluation periods."
  default     = 2
}

variable "alarm_period_seconds" {
  type        = number
  description = "Alarm period in seconds."
  default     = 60
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags to apply."
  default     = {}
}
