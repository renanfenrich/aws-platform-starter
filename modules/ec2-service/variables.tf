variable "name_prefix" {
  type        = string
  description = "Prefix used for naming EC2 resources."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the EC2 instances."
}

variable "security_group_id" {
  type        = string
  description = "Security group ID to attach to the instances."
}

variable "target_group_arn" {
  type        = string
  description = "Target group ARN for the Auto Scaling group."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type."
  default     = "t3.micro"

  validation {
    condition     = length(trimspace(var.instance_type)) > 0
    error_message = "instance_type must be a non-empty string."
  }
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of instances."
  default     = 1

  validation {
    condition     = var.desired_capacity >= var.min_size && var.desired_capacity <= var.max_size
    error_message = "desired_capacity must be between min_size and max_size."
  }
}

variable "min_size" {
  type        = number
  description = "Minimum number of instances."
  default     = 1

  validation {
    condition     = var.min_size >= 0
    error_message = "min_size must be zero or greater."
  }
}

variable "max_size" {
  type        = number
  description = "Maximum number of instances."
  default     = 1

  validation {
    condition     = var.max_size >= var.min_size
    error_message = "max_size must be greater than or equal to min_size."
  }
}

variable "health_check_grace_period_seconds" {
  type        = number
  description = "Grace period before ELB health checks start."
  default     = 60
}

variable "ami_id" {
  type        = string
  description = "Optional AMI ID override."
  default     = null
}

variable "user_data" {
  type        = string
  description = "Optional user data script for instance bootstrapping."
  default     = ""
}

variable "log_retention_in_days" {
  type        = number
  description = "Retention days for EC2 log group."
  default     = 30
}

variable "secrets_arns" {
  type        = list(string)
  description = "Secret ARNs the instance role can read."
  default     = []
}

variable "kms_key_arns" {
  type        = list(string)
  description = "KMS key ARNs used to decrypt secrets."
  default     = []

  validation {
    condition     = length(var.secrets_arns) == 0 || length(var.kms_key_arns) > 0
    error_message = "kms_key_arns must be provided when secrets_arns is set."
  }
}

variable "instance_role_policy_arns" {
  type        = list(string)
  description = "Additional policy ARNs to attach to the instance role."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to EC2 resources."
  default     = {}
}

variable "enable_detailed_monitoring" {
  type        = bool
  description = "Enable detailed monitoring for instances."
  default     = true
}
