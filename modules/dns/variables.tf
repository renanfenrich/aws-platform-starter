variable "name_prefix" {
  type        = string
  description = "Prefix used for naming resources in the parent stack."

  validation {
    condition     = length(var.name_prefix) <= 28
    error_message = "name_prefix must be <= 28 characters to stay within AWS naming limits."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags from the parent stack (Route53 records do not support tags)."

  validation {
    condition = alltrue([
      for key in ["Project", "Environment", "Service", "Owner", "CostCenter", "ManagedBy", "Repository"] :
      contains(keys(var.tags), key) && length(trimspace(var.tags[key])) > 0
    ])
    error_message = "tags must include non-empty Project, Environment, Service, Owner, CostCenter, ManagedBy, and Repository values."
  }
}

variable "enable_dns" {
  type        = bool
  description = "Enable Route53 record management."
  default     = false
}

variable "hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for record creation."
  default     = ""

  validation {
    condition     = !var.enable_dns || length(trimspace(var.hosted_zone_id)) > 0
    error_message = "hosted_zone_id must be set when enable_dns is true."
  }
}

variable "domain_name" {
  type        = string
  description = "Base domain name for the hosted zone (example.com)."
  default     = ""

  validation {
    condition     = !var.enable_dns || (length(trimspace(var.domain_name)) > 0 && !endswith(trimspace(var.domain_name), "."))
    error_message = "domain_name must be set when enable_dns is true and must not include a trailing dot."
  }
}

variable "record_name" {
  type        = string
  description = "Subdomain label for the record (empty string for apex)."
  default     = ""

  validation {
    condition     = var.record_name == "" || can(regex("^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$", var.record_name))
    error_message = "record_name must be empty or a single DNS label (letters, numbers, hyphens)."
  }
}

variable "create_apex_alias" {
  type        = bool
  description = "Create the apex alias record when record_name is empty."
  default     = true
}

variable "create_www_alias" {
  type        = bool
  description = "Create www alias records when record_name is empty."
  default     = false

  validation {
    condition     = !var.create_www_alias || var.record_name == ""
    error_message = "create_www_alias requires record_name to be empty (apex)."
  }
}

variable "create_aaaa" {
  type        = bool
  description = "Create AAAA alias records for IPv6."
  default     = true
}

variable "ttl" {
  type        = number
  description = "TTL for non-alias records (unused for ALB alias targets)."
  default     = 300

  validation {
    condition     = var.ttl > 0
    error_message = "ttl must be greater than 0."
  }
}

variable "target_type" {
  type        = string
  description = "Target type for the DNS records."
  default     = "alb"

  validation {
    condition     = contains(["alb"], var.target_type)
    error_message = "target_type must be \"alb\"."
  }
}

variable "alb_dns_name" {
  type        = string
  description = "ALB DNS name for Route53 alias targets."
  default     = ""

  validation {
    condition     = !var.enable_dns || length(trimspace(var.alb_dns_name)) > 0
    error_message = "alb_dns_name must be set when enable_dns is true."
  }
}

variable "alb_zone_id" {
  type        = string
  description = "Route53 zone ID for the ALB alias target."
  default     = ""

  validation {
    condition     = !var.enable_dns || length(trimspace(var.alb_zone_id)) > 0
    error_message = "alb_zone_id must be set when enable_dns is true."
  }
}
