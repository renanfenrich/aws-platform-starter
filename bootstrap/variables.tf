variable "aws_region" {
  type        = string
  description = "AWS region for the state resources."
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

variable "prevent_destroy" {
  type        = bool
  description = "Prevent destroying state resources."
  default     = true
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

variable "tags" {
  type        = map(string)
  description = "Tags considered for bootstrap resources."
  default     = {}
}
