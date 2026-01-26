variable "name_prefix" {
  type        = string
  description = "Prefix used for naming RDS resources."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the database."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the database subnet group."
}

variable "app_security_group_id" {
  type        = string
  description = "Security group ID for application tasks that need DB access."
}

variable "additional_ingress_security_group_ids" {
  type        = list(string)
  description = "Additional security group IDs allowed to access the database."
  default     = []

  validation {
    condition = alltrue([
      for sg_id in var.additional_ingress_security_group_ids : length(trimspace(sg_id)) > 0
    ])
    error_message = "additional_ingress_security_group_ids must not contain empty values."
  }
}

variable "db_name" {
  type        = string
  description = "Database name."
}

variable "db_username" {
  type        = string
  description = "Master username for the database."
}

variable "db_port" {
  type        = number
  description = "Database port."
  default     = 5432
}

variable "engine" {
  type        = string
  description = "Database engine."
  default     = "postgres"
}

variable "engine_version" {
  type        = string
  description = "Database engine version."
  default     = "15.4"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class."
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GB."
  default     = 20
}

variable "max_allocated_storage" {
  type        = number
  description = "Maximum storage in GB (autoscaling)."
  default     = 100
}

variable "storage_type" {
  type        = string
  description = "Storage type."
  default     = "gp3"
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ deployment."
  default     = false
}

variable "backup_retention_period" {
  type        = number
  description = "Backup retention in days."
  default     = 7
}

variable "maintenance_window" {
  type        = string
  description = "Preferred maintenance window."
  default     = "Mon:00:00-Mon:03:00"
}

variable "backup_window" {
  type        = string
  description = "Preferred backup window."
  default     = "03:00-04:00"
}

variable "enable_backup_plan" {
  type        = bool
  description = "Enable AWS Backup plan for the database."
  default     = false

  validation {
    condition     = !var.enable_backup_plan || length(trimspace(var.backup_plan_schedule)) > 0
    error_message = "backup_plan_schedule must be set when enable_backup_plan is true."
  }
}

variable "backup_vault_name" {
  type        = string
  description = "Optional override for the AWS Backup vault name."
  default     = null

  validation {
    condition     = var.backup_vault_name == null || length(trimspace(var.backup_vault_name)) > 0
    error_message = "backup_vault_name must be null or a non-empty string."
  }
}

variable "backup_plan_schedule" {
  type        = string
  description = "CRON schedule for AWS Backup (UTC)."
  default     = "cron(0 5 * * ? *)"
}

variable "backup_plan_start_window_minutes" {
  type        = number
  description = "Start window in minutes for AWS Backup jobs."
  default     = 60
}

variable "backup_plan_completion_window_minutes" {
  type        = number
  description = "Completion window in minutes for AWS Backup jobs."
  default     = 180
}

variable "backup_retention_days" {
  type        = number
  description = "Retention period in days for AWS Backup recovery points."
  default     = 35

  validation {
    condition     = var.backup_retention_days > 0
    error_message = "backup_retention_days must be greater than 0."
  }
}

variable "backup_copy_destination_vault_arn" {
  type        = string
  description = "Destination backup vault ARN for cross-region copy (optional)."
  default     = ""
}

variable "backup_copy_retention_days" {
  type        = number
  description = "Retention period in days for copied recovery points."
  default     = 35

  validation {
    condition     = var.backup_copy_retention_days > 0
    error_message = "backup_copy_retention_days must be greater than 0."
  }
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection."
  default     = true
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on deletion."
  default     = false
}

variable "final_snapshot_identifier" {
  type        = string
  description = "Final snapshot identifier to use when skip_final_snapshot is false."
  default     = null
}

variable "apply_immediately" {
  type        = bool
  description = "Apply changes immediately."
  default     = false
}

variable "publicly_accessible" {
  type        = bool
  description = "Whether the DB is publicly accessible."
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  description = "CloudWatch log exports to enable."
  default     = []
}

variable "kms_deletion_window_in_days" {
  type        = number
  description = "KMS key deletion window."
  default     = 30
}

variable "prevent_destroy" {
  type        = bool
  description = "Prevent destroying critical database resources."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to database resources."

  validation {
    condition = alltrue([
      for key in ["Project", "Environment", "Service", "Owner", "CostCenter", "ManagedBy", "Repository"] :
      contains(keys(var.tags), key) && length(trimspace(var.tags[key])) > 0
    ])
    error_message = "tags must include non-empty Project, Environment, Service, Owner, CostCenter, ManagedBy, and Repository values."
  }
}
