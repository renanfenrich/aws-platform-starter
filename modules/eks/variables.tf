variable "name_prefix" {
  type        = string
  description = "Prefix used for naming EKS resources."
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS control plane (major.minor)."
  default     = "1.29"

  validation {
    condition     = length(trimspace(var.cluster_version)) > 0
    error_message = "cluster_version must not be empty."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the EKS cluster."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block for security group rules."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the EKS cluster and node group."
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB security group ID allowed to reach the NodePort."
}

variable "alb_target_group_arn" {
  type        = string
  description = "ALB target group ARN to attach to the node group Auto Scaling group."
}

variable "ingress_nodeport" {
  type        = number
  description = "NodePort used by the ingress controller for ALB traffic."
  default     = 30080

  validation {
    condition     = var.ingress_nodeport >= 30000 && var.ingress_nodeport <= 32767
    error_message = "ingress_nodeport must be within the NodePort range (30000-32767)."
  }
}

variable "node_instance_type" {
  type        = string
  description = "Instance type for the EKS managed node group."
  default     = "t3.small"

  validation {
    condition     = length(trimspace(var.node_instance_type)) > 0
    error_message = "node_instance_type must not be empty."
  }
}

variable "node_min_size" {
  type        = number
  description = "Minimum size of the EKS node group."
  default     = 1
}

variable "node_max_size" {
  type        = number
  description = "Maximum size of the EKS node group."
  default     = 2
}

variable "node_desired_capacity" {
  type        = number
  description = "Desired size of the EKS node group."
  default     = 1
}

variable "node_disk_size" {
  type        = number
  description = "Disk size (GiB) for EKS nodes."
  default     = 20
}

variable "node_ami_type" {
  type        = string
  description = "AMI type for the EKS managed node group."
  default     = "AL2_x86_64"

  validation {
    condition = contains([
      "AL2_x86_64",
      "AL2_x86_64_GPU",
      "AL2_ARM_64",
      "AL2023_x86_64_STANDARD",
      "AL2023_ARM_64_STANDARD"
    ], var.node_ami_type)
    error_message = "node_ami_type must be a supported EKS AMI type."
  }
}

variable "endpoint_public_access" {
  type        = bool
  description = "Enable public access to the EKS API endpoint."
  default     = false
}

variable "endpoint_public_access_cidrs" {
  type        = list(string)
  description = "CIDR allowlist for the public EKS API endpoint."
  default     = []

  validation {
    condition     = !var.endpoint_public_access || length(var.endpoint_public_access_cidrs) > 0
    error_message = "endpoint_public_access_cidrs must be set when endpoint_public_access is true."
  }
}

variable "enable_admin_runner" {
  type        = bool
  description = "Enable the admin runner EC2 instance for kubectl access."
  default     = true
}

variable "admin_runner_instance_type" {
  type        = string
  description = "Instance type for the admin runner."
  default     = "t3.micro"

  validation {
    condition     = length(trimspace(var.admin_runner_instance_type)) > 0
    error_message = "admin_runner_instance_type must not be empty."
  }
}

variable "admin_runner_ami_id" {
  type        = string
  description = "Optional AMI ID override for the admin runner."
  default     = null
}

variable "admin_runner_ami_ssm_parameter" {
  type        = string
  description = "SSM parameter path for the admin runner AMI."
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to EKS resources."

  validation {
    condition = alltrue([
      for key in ["Project", "Environment", "Service", "Owner", "CostCenter", "ManagedBy", "Repository"] :
      contains(keys(var.tags), key) && length(trimspace(var.tags[key])) > 0
    ])
    error_message = "tags must include non-empty Project, Environment, Service, Owner, CostCenter, ManagedBy, and Repository values."
  }
}
