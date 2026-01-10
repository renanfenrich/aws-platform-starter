variable "name_prefix" {
  type        = string
  description = "Prefix used for naming Kubernetes EC2 resources."
}

variable "cluster_name" {
  type        = string
  description = "Kubernetes cluster name used by kubeadm."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for Kubernetes resources."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block for security group rules."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for control plane and worker nodes."
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB security group ID to allow ingress to the NodePort."
}

variable "alb_target_group_arn" {
  type        = string
  description = "ALB target group ARN to attach to the worker Auto Scaling group."
}

variable "control_plane_instance_type" {
  type        = string
  description = "EC2 instance type for the Kubernetes control plane."
}

variable "worker_instance_type" {
  type        = string
  description = "EC2 instance type for Kubernetes worker nodes."
}

variable "worker_min_size" {
  type        = number
  description = "Minimum size of the worker Auto Scaling group."
}

variable "worker_max_size" {
  type        = number
  description = "Maximum size of the worker Auto Scaling group."
}

variable "worker_desired_capacity" {
  type        = number
  description = "Desired size of the worker Auto Scaling group."
}

variable "health_check_grace_period_seconds" {
  type        = number
  description = "Grace period before Auto Scaling health checks start."
  default     = 300
}

variable "ami_id" {
  type        = string
  description = "Optional AMI ID override for Kubernetes nodes."
  default     = null
}

variable "ami_ssm_parameter" {
  type        = string
  description = "SSM parameter path for the Kubernetes node AMI."
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes version for kubeadm (ex: 1.29.2)."
  default     = "1.29.2"
}

variable "pod_cidr" {
  type        = string
  description = "CIDR for Kubernetes pods."
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  type        = string
  description = "CIDR for Kubernetes services."
  default     = "10.96.0.0/12"
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

variable "enable_ssm" {
  type        = bool
  description = "Attach SSM permissions for node access and bootstrap automation."
  default     = true
}

variable "enable_detailed_monitoring" {
  type        = bool
  description = "Enable detailed monitoring for Kubernetes nodes."
  default     = true
}

variable "instance_role_policy_arns" {
  type        = list(string)
  description = "Additional policy ARNs to attach to Kubernetes instance roles."
  default     = []
}

variable "join_parameter_name" {
  type        = string
  description = "Optional SSM parameter name for the kubeadm join command."
  default     = ""
}

variable "kms_deletion_window_in_days" {
  type        = number
  description = "KMS deletion window for the join parameter key."
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to Kubernetes resources."

  validation {
    condition = alltrue([
      for key in ["Project", "Environment", "Service", "Owner", "CostCenter", "ManagedBy", "Repository"] :
      contains(keys(var.tags), key) && length(trimspace(var.tags[key])) > 0
    ])
    error_message = "tags must include non-empty Project, Environment, Service, Owner, CostCenter, ManagedBy, and Repository values."
  }
}
