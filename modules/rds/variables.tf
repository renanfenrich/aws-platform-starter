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
