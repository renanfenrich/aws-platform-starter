variable "name_prefix" {
  type        = string
  description = "Prefix used for naming EC2 capacity resources."
}

variable "cluster_name" {
  type        = string
  description = "ECS cluster name for container instances."
}

variable "capacity_provider_name" {
  type        = string
  description = "Name for the ECS capacity provider."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the Auto Scaling group."
}

variable "security_group_id" {
  type        = string
  description = "Security group ID attached to the EC2 instances."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for container instances."
}

variable "min_size" {
  type        = number
  description = "Minimum size of the Auto Scaling group."
}

variable "max_size" {
  type        = number
  description = "Maximum size of the Auto Scaling group."
}

variable "desired_capacity" {
  type        = number
  description = "Desired size of the Auto Scaling group."
}

variable "ami_id" {
  type        = string
  description = "Optional AMI ID override for ECS container instances."
  default     = null
}

variable "ecs_ami_ssm_parameter" {
  type        = string
  description = "SSM parameter path for the ECS-optimized AMI."
  default     = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

variable "user_data" {
  type        = string
  description = "Additional user data appended after ECS cluster configuration."
  default     = ""
}

variable "enable_ssm" {
  type        = bool
  description = "Attach the SSM managed policy for Session Manager access."
  default     = true
}

variable "enable_detailed_monitoring" {
  type        = bool
  description = "Enable detailed monitoring for EC2 instances."
  default     = true
}

variable "instance_role_policy_arns" {
  type        = list(string)
  description = "Additional policy ARNs to attach to the instance role."
  default     = []
}

variable "health_check_grace_period_seconds" {
  type        = number
  description = "Grace period before Auto Scaling health checks start."
  default     = 60
}

variable "capacity_provider_target_capacity" {
  type        = number
  description = "Target capacity percentage for ECS managed scaling."
  default     = 100
}

variable "capacity_provider_min_scaling_step_size" {
  type        = number
  description = "Minimum scaling step size for ECS managed scaling."
  default     = 1
}

variable "capacity_provider_max_scaling_step_size" {
  type        = number
  description = "Maximum scaling step size for ECS managed scaling."
  default     = 1000
}

variable "enable_managed_scaling" {
  type        = bool
  description = "Enable ECS managed scaling for the capacity provider."
  default     = true
}

variable "enable_managed_termination_protection" {
  type        = bool
  description = "Enable ECS managed termination protection."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to EC2 capacity resources."
  default     = {}
}
