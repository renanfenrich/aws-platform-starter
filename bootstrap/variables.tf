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

variable "tags" {
  type        = map(string)
  description = "Tags considered for bootstrap resources."
  default     = {}
}
