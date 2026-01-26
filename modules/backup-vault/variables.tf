variable "name_prefix" {
  type        = string
  description = "Prefix used for naming the backup vault."
}

variable "vault_name_override" {
  type        = string
  description = "Optional backup vault name override."
  default     = null

  validation {
    condition     = var.vault_name_override == null ? true : length(trimspace(var.vault_name_override)) > 0
    error_message = "vault_name_override must be null or a non-empty string."
  }
}

variable "kms_deletion_window_in_days" {
  type        = number
  description = "KMS key deletion window (days) for backup vault encryption."
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to backup vault resources."

  validation {
    condition = alltrue([
      for key in ["Project", "Environment", "Service", "Owner", "CostCenter", "ManagedBy", "Repository"] :
      contains(keys(var.tags), key) && length(trimspace(var.tags[key])) > 0
    ])
    error_message = "tags must include non-empty Project, Environment, Service, Owner, CostCenter, ManagedBy, and Repository values."
  }
}
