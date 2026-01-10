variable "name_prefix" {
  type        = string
  description = "Prefix used for naming ALB resources."

  validation {
    condition     = length(var.name_prefix) <= 28
    error_message = "name_prefix must be <= 28 characters to keep ALB and target group names within AWS limits."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the ALB."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the VPC (used for restrictive egress)."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the ALB."
}

variable "target_port" {
  type        = number
  description = "Target port for the ALB target group."

  validation {
    condition     = var.target_port > 0 && var.target_port <= 65535
    error_message = "target_port must be a valid TCP port."
  }
}

variable "target_type" {
  type        = string
  description = "Target type for the ALB target group (ip for ECS, instance for EC2)."
  default     = "ip"

  validation {
    condition     = contains(["ip", "instance"], var.target_type)
    error_message = "target_type must be either \"ip\" or \"instance\"."
  }
}

variable "health_check_path" {
  type        = string
  description = "HTTP path for target group health checks."
  default     = "/"
}

variable "enable_http" {
  type        = bool
  description = "Enable HTTP listener (allowed in dev only)."
  default     = false
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS listener."

  validation {
    condition     = length(trimspace(var.acm_certificate_arn)) > 0
    error_message = "acm_certificate_arn must be provided for HTTPS."
  }
}

variable "ssl_policy" {
  type        = string
  description = "SSL policy for the HTTPS listener."
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "ingress_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to access the ALB."
  default     = ["0.0.0.0/0"]
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection for the ALB."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to ALB resources."

  validation {
    condition = alltrue([
      for key in ["Project", "Environment", "Service", "Owner", "CostCenter", "ManagedBy", "Repository"] :
      contains(keys(var.tags), key) && length(trimspace(var.tags[key])) > 0
    ])
    error_message = "tags must include non-empty Project, Environment, Service, Owner, CostCenter, ManagedBy, and Repository values."
  }
}
