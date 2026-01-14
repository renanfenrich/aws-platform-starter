variable "name_prefix" {
  type        = string
  description = "Prefix used for naming the ECR repository."
}

variable "service_name" {
  type        = string
  description = "Service name used in the repository name."

  validation {
    condition     = length(trimspace(var.service_name)) > 0
    error_message = "service_name must not be empty."
  }
}

variable "repository_name_override" {
  type        = string
  description = "Optional repository name override."
  default     = null

  validation {
    condition     = var.repository_name_override == null ? true : length(trimspace(var.repository_name_override)) > 0
    error_message = "repository_name_override must be null or a non-empty string."
  }
}

variable "immutable_tags" {
  type        = bool
  description = "Whether to enforce immutable image tags."
  default     = true
}

variable "scan_on_push" {
  type        = bool
  description = "Enable image scanning on push."
  default     = true
}

variable "lifecycle_keep_last" {
  type        = number
  description = "Number of untagged images to keep."
  default     = 30

  validation {
    condition     = var.lifecycle_keep_last > 0
    error_message = "lifecycle_keep_last must be greater than 0."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the ECR repository."

  validation {
    condition = alltrue([
      for key in ["Project", "Environment", "Service", "Owner", "CostCenter", "ManagedBy", "Repository"] :
      contains(keys(var.tags), key) && length(trimspace(var.tags[key])) > 0
    ])
    error_message = "tags must include non-empty Project, Environment, Service, Owner, CostCenter, ManagedBy, and Repository values."
  }
}
