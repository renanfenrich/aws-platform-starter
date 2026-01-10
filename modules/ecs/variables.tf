variable "name_prefix" {
  type        = string
  description = "Prefix used for naming ECS resources."
}

variable "environment" {
  type        = string
  description = "Environment name (dev/prod)."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the ECS service."
}

variable "security_group_id" {
  type        = string
  description = "Security group ID to attach to ECS tasks."
}

variable "target_group_arn" {
  type        = string
  description = "Target group ARN for the ECS service."
}

variable "capacity_providers" {
  type        = list(string)
  description = "Capacity providers associated with the ECS cluster."
  default     = ["FARGATE"]

  validation {
    condition     = length(var.capacity_providers) > 0
    error_message = "capacity_providers must include at least one provider."
  }
}

variable "default_capacity_provider_strategy" {
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = number
  }))
  description = "Default capacity provider strategy for the ECS cluster."
  default     = []
}

variable "capacity_provider_strategy" {
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = number
  }))
  description = "Capacity provider strategy for the ECS service."
  default     = []
}

variable "capacity_provider_dependency" {
  type        = any
  description = "Optional dependency to ensure capacity providers exist before association."
  default     = null
}

variable "container_image" {
  type        = string
  description = "Container image to run."
}

variable "container_port" {
  type        = number
  description = "Container port to expose."

  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "container_port must be a valid TCP port."
  }
}

variable "cpu" {
  type        = number
  description = "Task CPU units."
  default     = 256
}

variable "memory" {
  type        = number
  description = "Task memory (MiB)."
  default     = 512
}

variable "requires_compatibilities" {
  type        = list(string)
  description = "Task definition compatibilities (FARGATE or EC2)."
  default     = ["FARGATE"]
}

variable "desired_count" {
  type        = number
  description = "Desired number of tasks."
  default     = 1
}

variable "health_check_grace_period_seconds" {
  type        = number
  description = "Grace period before health checks start."
  default     = 60
}

variable "environment_variables" {
  type        = map(string)
  description = "Plaintext environment variables for the container."
  default     = {}
}

variable "container_secrets" {
  type        = map(string)
  description = "Secrets for the container (name => secret ARN)."
  default     = {}
}

variable "secrets_arns" {
  type        = list(string)
  description = "Secret ARNs that the execution role needs to access."
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

variable "log_retention_in_days" {
  type        = number
  description = "Retention days for ECS logs."
  default     = 30
}

variable "container_user" {
  type        = string
  description = "User ID for the container process (non-root by default)."
  default     = "1000"
}

variable "readonly_root_filesystem" {
  type        = bool
  description = "Run the container with a read-only root filesystem."
  default     = false
}

variable "enable_execute_command" {
  type        = bool
  description = "Enable ECS exec."
  default     = true
}

variable "enable_container_insights" {
  type        = bool
  description = "Enable ECS container insights."
  default     = true
}

variable "deployment_minimum_healthy_percent" {
  type        = number
  description = "Minimum healthy percent for deployments."
  default     = 50
}

variable "deployment_maximum_percent" {
  type        = number
  description = "Maximum percent for deployments."
  default     = 200
}

variable "task_role_policy_arns" {
  type        = list(string)
  description = "Additional policy ARNs to attach to the task role."
  default     = []
}

variable "assign_public_ip" {
  type        = bool
  description = "Assign public IPs to tasks."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to ECS resources."

  validation {
    condition = alltrue([
      for key in ["Project", "Environment", "Service", "Owner", "CostCenter", "ManagedBy", "Repository"] :
      contains(keys(var.tags), key) && length(trimspace(var.tags[key])) > 0
    ])
    error_message = "tags must include non-empty Project, Environment, Service, Owner, CostCenter, ManagedBy, and Repository values."
  }
}
