variable "project_name" {
  type        = string
  description = "Project name used for resource naming."

  validation {
    condition     = length("${var.project_name}-${var.environment}") <= 28
    error_message = "project_name and environment must be <= 28 characters combined to stay consistent with platform naming limits."
  }
}

variable "environment" {
  type        = string
  description = "Environment name (dev or prod)."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "service_name" {
  type        = string
  description = "Service identifier used for cost allocation."

  validation {
    condition     = length(trimspace(var.service_name)) > 0
    error_message = "service_name must not be empty."
  }
}

variable "owner" {
  type        = string
  description = "Owning team or individual for cost allocation."

  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "owner must not be empty."
  }
}

variable "cost_center" {
  type        = string
  description = "Cost center identifier for chargeback/showback."

  validation {
    condition     = length(trimspace(var.cost_center)) > 0
    error_message = "cost_center must not be empty."
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for the example stack."

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must not be empty."
  }
}

variable "state_bucket" {
  type        = string
  description = "S3 bucket holding the environment Terraform state."

  validation {
    condition     = length(trimspace(var.state_bucket)) > 0
    error_message = "state_bucket must not be empty."
  }
}

variable "state_key" {
  type        = string
  description = "S3 key for the environment Terraform state (defaults to <project>/<environment>/terraform.tfstate)."
  default     = ""
}

variable "state_region" {
  type        = string
  description = "Region for the environment state bucket (defaults to aws_region)."
  default     = ""
}

variable "image_tag" {
  type        = string
  description = "Image tag to use with the environment ECR repository."
  default     = "latest"

  validation {
    condition     = length(trimspace(var.image_tag)) > 0
    error_message = "image_tag must not be empty."
  }
}

variable "desired_count" {
  type        = number
  description = "Desired task count for the example ECS service."
  default     = 0

  validation {
    condition     = var.desired_count >= 0
    error_message = "desired_count must be 0 or greater."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Optional tags to merge with the required platform tags."
  default     = {}

  validation {
    condition     = length(setintersection(keys(var.additional_tags), ["Project", "Environment", "Service", "Owner", "CostCenter", "ManagedBy", "Repository"])) == 0
    error_message = "additional_tags must not override required platform tags."
  }
}
