variable "name_prefix" {
  type        = string
  description = "Prefix used for naming network resources."
}

variable "aws_region" {
  type        = string
  description = "AWS region for VPC endpoint service names."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "azs" {
  type        = list(string)
  description = "Availability zones to use."

  validation {
    condition     = length(var.azs) >= 2
    error_message = "Provide at least two availability zones."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets (one per AZ)."

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.azs)
    error_message = "public_subnet_cidrs must match the number of azs."
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets (one per AZ)."

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.azs)
    error_message = "private_subnet_cidrs must match the number of azs."
  }
}

variable "single_nat_gateway" {
  type        = bool
  description = "Whether to use a single NAT gateway (cost-saving, less resilient)."
  default     = false
}

variable "enable_gateway_endpoints" {
  type        = bool
  description = "Enable gateway VPC endpoints for S3 and DynamoDB."
  default     = true
}

variable "enable_interface_endpoints" {
  type        = bool
  description = "Enable interface VPC endpoints for ECR, CloudWatch Logs, and SSM."
  default     = false
}

variable "enable_flow_logs" {
  type        = bool
  description = "Enable VPC flow logs to CloudWatch Logs."
  default     = true
}

variable "flow_logs_retention_in_days" {
  type        = number
  description = "Retention for VPC flow logs in CloudWatch."
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to network resources."

  validation {
    condition = alltrue([
      for key in ["Project", "Environment", "Service", "Owner", "CostCenter", "ManagedBy", "Repository"] :
      contains(keys(var.tags), key) && length(trimspace(var.tags[key])) > 0
    ])
    error_message = "tags must include non-empty Project, Environment, Service, Owner, CostCenter, ManagedBy, and Repository values."
  }
}
