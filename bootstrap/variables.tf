variable "aws_region" {
  type        = string
  description = "AWS region for the state resources."
}

variable "project_name" {
  type        = string
  description = "Project name for naming bootstrap resources."

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name must not be empty."
  }
}

variable "environment" {
  type        = string
  description = "Environment name for naming bootstrap resources."

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must not be empty."
  }
}

variable "region_short" {
  type        = string
  description = "Short region identifier for naming (example: use1)."

  validation {
    condition     = length(trimspace(var.region_short)) > 0
    error_message = "region_short must not be empty."
  }
}

variable "state_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for Terraform state."
}

variable "lock_table_name" {
  type        = string
  description = "Name of the DynamoDB table for state locking."
}

variable "log_bucket_name" {
  type        = string
  description = "Optional name of the S3 bucket for state access logs."
  default     = null
}

variable "force_destroy" {
  type        = bool
  description = "Allow destroying the state bucket (not recommended)."
  default     = false
}

variable "kms_deletion_window_in_days" {
  type        = number
  description = "KMS key deletion window (days) for state encryption."
  default     = 30
}

variable "enable_lock_table_pitr" {
  type        = bool
  description = "Enable point-in-time recovery for the lock table."
  default     = true
}

variable "sns_email_subscriptions" {
  type        = list(string)
  description = "Email addresses to subscribe to infrastructure SNS notifications."
  default     = []

  validation {
    condition = alltrue([
      for email in var.sns_email_subscriptions : length(trimspace(email)) > 0
    ])
    error_message = "sns_email_subscriptions must not contain empty values."
  }
}

variable "acm_domain_name" {
  type        = string
  description = "Optional domain name for ACM certificate (requires acm_zone_id)."
  default     = ""

  validation {
    condition     = (length(trimspace(var.acm_domain_name)) == 0 && length(trimspace(var.acm_zone_id)) == 0) || (length(trimspace(var.acm_domain_name)) > 0 && length(trimspace(var.acm_zone_id)) > 0)
    error_message = "acm_domain_name and acm_zone_id must be set together to enable ACM DNS validation."
  }
}

variable "acm_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for ACM DNS validation (required when acm_domain_name is set)."
  default     = ""
}

variable "acm_subject_alternative_names" {
  type        = list(string)
  description = "Optional subject alternative names for the ACM certificate."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags considered for bootstrap resources."
  default     = {}
}
