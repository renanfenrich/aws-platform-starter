variable "name_prefix" {
  type        = string
  description = "Prefix used for naming API Gateway and Lambda resources."

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix must not be empty."
  }
}

variable "environment" {
  type        = string
  description = "Environment name for labeling (dev or prod)."

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must not be empty."
  }
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days."
  default     = 30

  validation {
    condition = contains([
      1,
      3,
      5,
      7,
      14,
      30,
      60,
      90,
      120,
      150,
      180,
      365,
      400,
      545,
      731,
      1827,
      3653
    ], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch Logs retention value."
  }
}

variable "log_kms_key_id" {
  type        = string
  description = "Optional KMS key ID for encrypting CloudWatch log groups."
  default     = null

  validation {
    condition     = var.log_kms_key_id == null || length(trimspace(coalesce(var.log_kms_key_id, ""))) > 0
    error_message = "log_kms_key_id must be null or a non-empty string."
  }
}

variable "enable_xray" {
  type        = bool
  description = "Enable AWS X-Ray tracing for the Lambda function."
  default     = false
}

variable "cors_allowed_origins" {
  type        = list(string)
  description = "Allowed CORS origins (empty list disables CORS)."
  default     = []

  validation {
    condition = alltrue([
      for origin in var.cors_allowed_origins : length(trimspace(origin)) > 0
    ])
    error_message = "cors_allowed_origins must not contain empty values."
  }
}

variable "throttle_burst_limit" {
  type        = number
  description = "Burst rate limit for the API Gateway default route settings."
  default     = 50

  validation {
    condition     = var.throttle_burst_limit > 0 && var.throttle_burst_limit <= 5000
    error_message = "throttle_burst_limit must be between 1 and 5000."
  }

  validation {
    condition     = var.throttle_burst_limit >= var.throttle_rate_limit
    error_message = "throttle_burst_limit must be greater than or equal to throttle_rate_limit."
  }
}

variable "throttle_rate_limit" {
  type        = number
  description = "Steady-state rate limit (requests per second) for the API Gateway default route settings."
  default     = 25

  validation {
    condition     = var.throttle_rate_limit > 0 && var.throttle_rate_limit <= 10000
    error_message = "throttle_rate_limit must be between 1 and 10000."
  }
}

variable "additional_route_keys" {
  type        = list(string)
  description = "Additional API Gateway route keys (for example, GET /info)."
  default     = []

  validation {
    condition = alltrue([
      for route in var.additional_route_keys : length(trimspace(route)) > 0
    ])
    error_message = "additional_route_keys must not contain empty values."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the Lambda security group."
  default     = null

  validation {
    condition     = length(var.vpc_subnet_ids) == 0 || (var.vpc_id != null && length(trimspace(var.vpc_id)) > 0)
    error_message = "vpc_id must be set when vpc_subnet_ids are provided."
  }
}

variable "vpc_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for Lambda (empty list disables VPC config)."
  default     = []
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "Additional security group IDs to attach to the Lambda function."
  default     = []

  validation {
    condition     = length(var.vpc_subnet_ids) > 0 || length(var.vpc_security_group_ids) == 0
    error_message = "vpc_security_group_ids can only be set when vpc_subnet_ids are provided."
  }
}

variable "enable_rds_access" {
  type        = bool
  description = "Allow Lambda egress to the RDS security group on port 5432."
  default     = false

  validation {
    condition     = !var.enable_rds_access || length(var.vpc_subnet_ids) > 0
    error_message = "enable_rds_access requires vpc_subnet_ids to be set."
  }
}

variable "rds_security_group_id" {
  type        = string
  description = "RDS security group ID to allow egress when enable_rds_access is true."
  default     = null

  validation {
    condition     = !var.enable_rds_access || (var.rds_security_group_id != null && length(trimspace(var.rds_security_group_id)) > 0)
    error_message = "rds_security_group_id must be set when enable_rds_access is true."
  }
}

variable "rds_secret_arn" {
  type        = string
  description = "Optional Secrets Manager ARN for the database (passed as an env var)."
  default     = null

  validation {
    condition     = var.rds_secret_arn == null || length(trimspace(coalesce(var.rds_secret_arn, ""))) > 0
    error_message = "rds_secret_arn must be null or a non-empty string."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources in the module."

  validation {
    condition = alltrue([
      for key in ["Project", "Environment", "Service", "Owner", "CostCenter", "ManagedBy", "Repository"] :
      contains(keys(var.tags), key) && length(trimspace(var.tags[key])) > 0
    ])
    error_message = "tags must include non-empty Project, Environment, Service, Owner, CostCenter, ManagedBy, and Repository values."
  }
}
