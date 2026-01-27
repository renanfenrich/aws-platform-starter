variable "project_name" {
  type        = string
  description = "Project name used for resource naming."

  validation {
    condition     = length("${var.project_name}-${var.environment}") <= 28
    error_message = "project_name and environment must be <= 28 characters combined to satisfy ALB and target group naming limits."
  }
}

variable "environment" {
  type        = string
  description = "Environment name (dr)."

  validation {
    condition     = var.environment == "dr"
    error_message = "environment must be dr."
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

variable "cost_posture" {
  type        = string
  description = "FinOps cost posture (cost_optimized or stability_first)."

  validation {
    condition     = contains(["cost_optimized", "stability_first"], var.cost_posture)
    error_message = "cost_posture must be cost_optimized or stability_first."
  }

  validation {
    condition     = var.cost_posture == "cost_optimized"
    error_message = "cost_posture must be cost_optimized for dr."
  }
}

variable "allow_spot_in_prod" {
  type        = bool
  description = "Allow Fargate Spot capacity in prod (default is false)."
  default     = false
}

variable "enforce_cost_controls" {
  type        = bool
  description = "Block deploys when estimated costs exceed the hard threshold."
  default     = true
}

variable "estimated_monthly_cost" {
  type        = number
  description = "Estimated monthly cost (USD) injected by CI."
  default     = null
  nullable    = true

  validation {
    condition     = var.estimated_monthly_cost == null || var.estimated_monthly_cost >= 0
    error_message = "estimated_monthly_cost must be greater than or equal to 0."
  }
}

variable "budget_limit_usd" {
  type        = number
  description = "Monthly budget limit in USD."

  validation {
    condition     = var.budget_limit_usd > 0
    error_message = "budget_limit_usd must be greater than 0."
  }
}

variable "budget_warning_threshold_percent" {
  type        = number
  description = "Warning threshold percentage for budget notifications."

  validation {
    condition     = var.budget_warning_threshold_percent > 0 && var.budget_warning_threshold_percent < 100
    error_message = "budget_warning_threshold_percent must be between 0 and 100."
  }
}

variable "budget_hard_limit_percent" {
  type        = number
  description = "Hard limit percentage used for deploy-time enforcement."

  validation {
    condition     = var.budget_hard_limit_percent > var.budget_warning_threshold_percent && var.budget_hard_limit_percent <= 100
    error_message = "budget_hard_limit_percent must be greater than budget_warning_threshold_percent and <= 100."
  }
}

variable "budget_notification_emails" {
  type        = list(string)
  description = "Email recipients for budget alerts."
  default     = []

  validation {
    condition = alltrue([
      for email in var.budget_notification_emails : length(trimspace(email)) > 0
    ])
    error_message = "budget_notification_emails must not contain empty values."
  }

  validation {
    condition     = length(var.budget_notification_emails) > 0 || length(trimspace(var.budget_sns_topic_arn)) > 0 || length(trimspace(var.alarm_sns_topic_arn)) > 0
    error_message = "Set budget_notification_emails, budget_sns_topic_arn, or alarm_sns_topic_arn for budget alerts."
  }
}

variable "budget_sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for budget alerts (optional override)."
  default     = ""
}

variable "platform" {
  type        = string
  description = "Platform selection (ecs, k8s_self_managed, or eks)."
  default     = "ecs"

  validation {
    condition     = contains(["ecs", "k8s_self_managed", "eks"], var.platform)
    error_message = "platform must be ecs, k8s_self_managed, or eks."
  }
}

variable "ecs_capacity_mode" {
  type        = string
  description = "ECS capacity mode (fargate, fargate_spot, or ec2)."
  default     = "fargate"

  validation {
    condition     = contains(["fargate", "fargate_spot", "ec2"], var.ecs_capacity_mode) && (var.environment == "dev" || var.environment == "dr" || var.ecs_capacity_mode != "fargate_spot" || var.allow_spot_in_prod)
    error_message = "ecs_capacity_mode must be fargate, fargate_spot, or ec2. Fargate Spot in prod requires allow_spot_in_prod = true."
  }
}

variable "k8s_control_plane_instance_type" {
  type        = string
  description = "EC2 instance type for the Kubernetes control plane."
  default     = "t3.small"
}

variable "k8s_worker_instance_type" {
  type        = string
  description = "EC2 instance type for Kubernetes worker nodes."
  default     = "t3.small"
}

variable "k8s_worker_desired_capacity" {
  type        = number
  description = "Desired capacity for the Kubernetes worker Auto Scaling group."
  default     = 0
}

variable "k8s_worker_min_size" {
  type        = number
  description = "Minimum size for the Kubernetes worker Auto Scaling group."
  default     = 0
}

variable "k8s_worker_max_size" {
  type        = number
  description = "Maximum size for the Kubernetes worker Auto Scaling group."
  default     = 2
}

variable "k8s_ami_id" {
  type        = string
  description = "Optional AMI ID override for Kubernetes nodes."
  default     = null
}

variable "k8s_ami_ssm_parameter" {
  type        = string
  description = "SSM parameter path for the Kubernetes node AMI."
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes version to install (minor or patch)."
  default     = "1.29.2"
}

variable "k8s_pod_cidr" {
  type        = string
  description = "Pod CIDR for the Kubernetes cluster."
  default     = "10.244.0.0/16"
}

variable "k8s_service_cidr" {
  type        = string
  description = "Service CIDR for the Kubernetes cluster."
  default     = "10.96.0.0/12"
}

variable "k8s_ingress_nodeport" {
  type        = number
  description = "NodePort used by the Kubernetes ingress controller."
  default     = 30080

  validation {
    condition     = var.k8s_ingress_nodeport >= 30000 && var.k8s_ingress_nodeport <= 32767
    error_message = "k8s_ingress_nodeport must be within the NodePort range (30000-32767)."
  }
}

variable "k8s_enable_ssm" {
  type        = bool
  description = "Attach SSM permissions for Kubernetes nodes."
  default     = true
}

variable "k8s_enable_detailed_monitoring" {
  type        = bool
  description = "Enable detailed monitoring for Kubernetes nodes."
  default     = true
}

variable "k8s_instance_role_policy_arns" {
  type        = list(string)
  description = "Additional policy ARNs to attach to Kubernetes instance roles."
  default     = []
}

variable "k8s_join_parameter_name" {
  type        = string
  description = "Optional override for the SSM parameter storing the kubeadm join command."
  default     = ""
}

variable "eks_cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS control plane (major.minor)."
  default     = "1.29"

  validation {
    condition     = length(trimspace(var.eks_cluster_version)) > 0
    error_message = "eks_cluster_version must not be empty."
  }
}

variable "eks_node_instance_type" {
  type        = string
  description = "Instance type for the EKS managed node group."
  default     = "t3.small"

  validation {
    condition     = length(trimspace(var.eks_node_instance_type)) > 0
    error_message = "eks_node_instance_type must not be empty."
  }
}

variable "eks_node_desired_capacity" {
  type        = number
  description = "Desired size of the EKS node group."
  default     = 0
}

variable "eks_node_min_size" {
  type        = number
  description = "Minimum size of the EKS node group."
  default     = 0
}

variable "eks_node_max_size" {
  type        = number
  description = "Maximum size of the EKS node group."
  default     = 2
}

variable "eks_node_disk_size" {
  type        = number
  description = "Disk size (GiB) for EKS nodes."
  default     = 20
}

variable "eks_node_ami_type" {
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
    ], var.eks_node_ami_type)
    error_message = "eks_node_ami_type must be a supported EKS AMI type."
  }
}

variable "eks_ingress_nodeport" {
  type        = number
  description = "NodePort used by the EKS ingress controller."
  default     = 30080

  validation {
    condition     = var.eks_ingress_nodeport >= 30000 && var.eks_ingress_nodeport <= 32767
    error_message = "eks_ingress_nodeport must be within the NodePort range (30000-32767)."
  }
}

variable "eks_endpoint_public_access" {
  type        = bool
  description = "Enable public access to the EKS API endpoint."
  default     = false
}

variable "eks_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "CIDR allowlist for the public EKS API endpoint."
  default     = []

  validation {
    condition     = !var.eks_endpoint_public_access || length(var.eks_endpoint_public_access_cidrs) > 0
    error_message = "eks_endpoint_public_access_cidrs must be set when eks_endpoint_public_access is true."
  }
}

variable "eks_enable_admin_runner" {
  type        = bool
  description = "Enable the admin runner EC2 instance for kubectl access."
  default     = true
}

variable "eks_admin_runner_instance_type" {
  type        = string
  description = "Instance type for the EKS admin runner."
  default     = "t3.micro"

  validation {
    condition     = length(trimspace(var.eks_admin_runner_instance_type)) > 0
    error_message = "eks_admin_runner_instance_type must not be empty."
  }
}

variable "eks_admin_runner_ami_id" {
  type        = string
  description = "Optional AMI ID override for the EKS admin runner."
  default     = null

  validation {
    condition     = var.eks_admin_runner_ami_id == null ? true : length(trimspace(var.eks_admin_runner_ami_id)) > 0
    error_message = "eks_admin_runner_ami_id must be null or a non-empty string."
  }
}

variable "eks_admin_runner_ami_ssm_parameter" {
  type        = string
  description = "SSM parameter path for the EKS admin runner AMI."
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy into."
}

variable "allowed_account_ids" {
  type        = list(string)
  description = "Optional list of AWS account IDs allowed to run this config."
  default     = []
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs (2 subnets)."

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "public_subnet_cidrs must contain two CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs (2 subnets)."

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "private_subnet_cidrs must contain two CIDR blocks."
  }
}

variable "single_nat_gateway" {
  type        = bool
  description = "Use a single NAT gateway to reduce cost."
  default     = true
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
  description = "Enable VPC flow logs."
  default     = false
}

variable "flow_logs_retention_in_days" {
  type        = number
  description = "Retention period for VPC flow logs."
  default     = 30
}

variable "alb_enable_public_ingress" {
  type        = bool
  description = "Enable public ALB listeners and ingress."
  default     = false
}

variable "allow_http" {
  type        = bool
  description = "Allow HTTP listener (dev only)."
  default     = false

  validation {
    condition     = !var.allow_http
    error_message = "allow_http must be false in dr."
  }

  validation {
    condition     = !var.allow_http || var.alb_enable_public_ingress
    error_message = "allow_http requires alb_enable_public_ingress = true."
  }
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS."
}

variable "alb_ingress_cidrs" {
  type        = list(string)
  description = "Allowed CIDR ranges for ALB ingress."
  default     = ["0.0.0.0/0"]
}

variable "alb_deletion_protection" {
  type        = bool
  description = "Enable ALB deletion protection."
  default     = false
}

variable "alb_enable_access_logs" {
  type        = bool
  description = "Enable ALB access logs."
  default     = false

  validation {
    condition     = var.environment != "prod" || var.alb_enable_access_logs
    error_message = "alb_enable_access_logs must be true in prod."
  }
}

variable "alb_access_logs_bucket" {
  type        = string
  description = "S3 bucket name for ALB access logs."
  default     = null

  validation {
    condition     = !var.alb_enable_access_logs || (var.alb_access_logs_bucket != null && length(trimspace(var.alb_access_logs_bucket)) > 0)
    error_message = "alb_access_logs_bucket must be set when alb_enable_access_logs is true."
  }
}

variable "alb_enable_waf" {
  type        = bool
  description = "Enable WAF web ACL association for the ALB."
  default     = false
}

variable "alb_waf_acl_arn" {
  type        = string
  description = "WAF web ACL ARN to associate with the ALB."
  default     = null

  validation {
    condition     = !var.alb_enable_waf || (var.alb_waf_acl_arn != null && length(trimspace(var.alb_waf_acl_arn)) > 0)
    error_message = "alb_waf_acl_arn must be set when alb_enable_waf is true."
  }
}

variable "container_image" {
  type        = string
  description = "Container image to deploy (optional override)."
  default     = null

  validation {
    condition     = var.container_image == null ? true : length(trimspace(var.container_image)) > 0
    error_message = "container_image must be null or a non-empty string."
  }
}

variable "ecr_enable_replication" {
  type        = bool
  description = "Enable cross-region ECR replication for this environment."
  default     = false

  validation {
    condition     = !var.ecr_enable_replication || length(var.ecr_replication_regions) > 0
    error_message = "ecr_replication_regions must be set when ecr_enable_replication is true."
  }
}

variable "ecr_replication_regions" {
  type        = list(string)
  description = "Destination regions for ECR replication."
  default     = []

  validation {
    condition = alltrue([
      for region in var.ecr_replication_regions : length(trimspace(region)) > 0
    ])
    error_message = "ecr_replication_regions must not contain empty values."
  }
}

variable "ecr_replication_filter_prefixes" {
  type        = list(string)
  description = "Repository name prefixes to replicate (defaults to the repository name)."
  default     = []

  validation {
    condition = alltrue([
      for prefix in var.ecr_replication_filter_prefixes : length(trimspace(prefix)) > 0
    ])
    error_message = "ecr_replication_filter_prefixes must not contain empty values."
  }
}

variable "image_tag" {
  type        = string
  description = "Image tag to use when container_image is not set."
  default     = "latest"

  validation {
    condition     = length(trimspace(var.image_tag)) > 0
    error_message = "image_tag must not be empty."
  }
}

variable "container_port" {
  type        = number
  description = "Container port exposed by the application."
}

variable "container_cpu" {
  type        = number
  description = "CPU units for the task."
  default     = 256
}

variable "container_memory" {
  type        = number
  description = "Memory (MiB) for the task."
  default     = 512
}

variable "desired_count" {
  type        = number
  description = "Desired number of ECS tasks."
  default     = 0
}

variable "enable_autoscaling" {
  type        = bool
  description = "Enable ECS service autoscaling for desired count."
  default     = false
}

variable "autoscaling_min_capacity" {
  type        = number
  description = "Minimum task count when autoscaling is enabled."
  default     = 2

  validation {
    condition     = var.autoscaling_min_capacity >= 1
    error_message = "autoscaling_min_capacity must be at least 1."
  }
}

variable "autoscaling_max_capacity" {
  type        = number
  description = "Maximum task count when autoscaling is enabled."
  default     = 6

  validation {
    condition     = var.autoscaling_max_capacity >= var.autoscaling_min_capacity
    error_message = "autoscaling_max_capacity must be greater than or equal to autoscaling_min_capacity."
  }
}

variable "autoscaling_target_cpu" {
  type        = number
  description = "Target CPU utilization percentage for autoscaling."
  default     = 50

  validation {
    condition     = var.autoscaling_target_cpu >= 10 && var.autoscaling_target_cpu <= 90
    error_message = "autoscaling_target_cpu must be between 10 and 90."
  }
}

variable "autoscaling_scale_in_cooldown" {
  type        = number
  description = "Cooldown in seconds before scaling in."
  default     = 120

  validation {
    condition     = var.autoscaling_scale_in_cooldown >= 0
    error_message = "autoscaling_scale_in_cooldown must be greater than or equal to 0."
  }
}

variable "autoscaling_scale_out_cooldown" {
  type        = number
  description = "Cooldown in seconds before scaling out."
  default     = 120

  validation {
    condition     = var.autoscaling_scale_out_cooldown >= 0
    error_message = "autoscaling_scale_out_cooldown must be greater than or equal to 0."
  }
}

variable "health_check_path" {
  type        = string
  description = "Health check path for the ALB target group."
  default     = "/"
}

variable "health_check_grace_period_seconds" {
  type        = number
  description = "Grace period before ALB health checks start."
  default     = 60
}

variable "container_user" {
  type        = string
  description = "User ID for the container process."
  default     = "1000"
}

variable "readonly_root_filesystem" {
  type        = bool
  description = "Run containers with a read-only root filesystem."
  default     = false
}

variable "enable_execute_command" {
  type        = bool
  description = "Enable ECS Exec for troubleshooting."
  default     = true
}

variable "enable_container_insights" {
  type        = bool
  description = "Enable ECS container insights."
  default     = true
}

variable "deployment_minimum_healthy_percent" {
  type        = number
  description = "Minimum healthy percent during deployments."
  default     = 50
}

variable "deployment_maximum_percent" {
  type        = number
  description = "Maximum percent during deployments."
  default     = 200
}

variable "log_retention_in_days" {
  type        = number
  description = "Retention for compute logs."
  default     = 7
}

variable "enable_serverless_api" {
  type        = bool
  description = "Enable the optional API Gateway + Lambda serverless API."
  default     = false
}

variable "serverless_api_log_retention_days" {
  type        = number
  description = "Retention for serverless API logs."
  default     = 7

  validation {
    condition = contains([
      1,
      3,
      5,
      7,
      14,
      30,
      60,
      90,
      120,
      150,
      180,
      365,
      400,
      545,
      731,
      1827,
      3653
    ], var.serverless_api_log_retention_days)
    error_message = "serverless_api_log_retention_days must be a valid CloudWatch Logs retention value."
  }
}

variable "serverless_api_enable_xray" {
  type        = bool
  description = "Enable X-Ray tracing for the serverless API."
  default     = false
}

variable "serverless_api_cors_allowed_origins" {
  type        = list(string)
  description = "Allowed CORS origins for the serverless API (empty list disables CORS)."
  default     = []

  validation {
    condition = alltrue([
      for origin in var.serverless_api_cors_allowed_origins : length(trimspace(origin)) > 0
    ])
    error_message = "serverless_api_cors_allowed_origins must not contain empty values."
  }
}

variable "serverless_api_additional_route_keys" {
  type        = list(string)
  description = "Additional serverless API route keys (for example, GET /info)."
  default     = []

  validation {
    condition = alltrue([
      for route in var.serverless_api_additional_route_keys : length(trimspace(route)) > 0
    ])
    error_message = "serverless_api_additional_route_keys must not contain empty values."
  }
}

variable "serverless_api_enable_rds_access" {
  type        = bool
  description = "Allow the serverless API Lambda to reach RDS on port 5432."
  default     = false

  validation {
    condition     = !var.serverless_api_enable_rds_access || var.enable_serverless_api
    error_message = "serverless_api_enable_rds_access requires enable_serverless_api to be true."
  }
}

variable "serverless_api_rds_secret_arn" {
  type        = string
  description = "Optional Secrets Manager ARN passed to the serverless API Lambda."
  default     = null

  validation {
    condition     = var.serverless_api_rds_secret_arn == null ? true : length(trimspace(var.serverless_api_rds_secret_arn)) > 0
    error_message = "serverless_api_rds_secret_arn must be null or a non-empty string."
  }
}

variable "ec2_instance_type" {
  type        = string
  description = "EC2 instance type for ECS capacity provider instances."
  default     = "t3.micro"
}

variable "ec2_desired_capacity" {
  type        = number
  description = "Desired capacity for the ECS EC2 Auto Scaling group."
  default     = null
}

variable "ec2_min_size" {
  type        = number
  description = "Minimum EC2 instances for the ECS capacity provider Auto Scaling group."
  default     = null
}

variable "ec2_max_size" {
  type        = number
  description = "Maximum EC2 instances for the ECS capacity provider Auto Scaling group."
  default     = null
}

variable "ec2_ami_id" {
  type        = string
  description = "Optional AMI ID override for ECS-optimized instances."
  default     = null
}

variable "ec2_user_data" {
  type        = string
  description = "Optional user data appended to the ECS instance bootstrap."
  default     = ""
}

variable "ec2_enable_ssm" {
  type        = bool
  description = "Attach SSM permissions for ECS EC2 instances."
  default     = true
}

variable "ec2_enable_detailed_monitoring" {
  type        = bool
  description = "Enable detailed monitoring for ECS EC2 instances."
  default     = true
}

variable "ec2_instance_role_policy_arns" {
  type        = list(string)
  description = "Additional policy ARNs to attach to the ECS EC2 instance role."
  default     = []
}

variable "db_name" {
  type        = string
  description = "Database name."
}

variable "db_username" {
  type        = string
  description = "Database master username."
}

variable "db_port" {
  type        = number
  description = "Database port."
  default     = 5432
}

variable "db_engine" {
  type        = string
  description = "Database engine."
  default     = "postgres"
}

variable "db_engine_version" {
  type        = string
  description = "Database engine version."
  default     = "15.4"
}

variable "db_instance_class" {
  type        = string
  description = "Database instance class."
}

variable "db_allocated_storage" {
  type        = number
  description = "Allocated storage (GB)."
  default     = 20
}

variable "db_max_allocated_storage" {
  type        = number
  description = "Max storage (GB)."
  default     = 100
}

variable "db_storage_type" {
  type        = string
  description = "Storage type."
  default     = "gp3"
}

variable "db_multi_az" {
  type        = bool
  description = "Enable Multi-AZ for RDS."
  default     = false
}

variable "db_backup_retention_period" {
  type        = number
  description = "Backup retention period in days."
  default     = 1
}

variable "db_maintenance_window" {
  type        = string
  description = "RDS maintenance window."
  default     = "Mon:00:00-Mon:03:00"
}

variable "db_backup_window" {
  type        = string
  description = "RDS backup window."
  default     = "03:00-04:00"
}

variable "enable_rds_backup" {
  type        = bool
  description = "Enable AWS Backup plan for the RDS instance."
  default     = false

  validation {
    condition     = !var.enable_rds_backup || length(trimspace(var.rds_backup_schedule)) > 0
    error_message = "rds_backup_schedule must be set when enable_rds_backup is true."
  }
}

variable "rds_backup_vault_name" {
  type        = string
  description = "Optional override for the AWS Backup vault name."
  default     = null

  validation {
    condition     = var.rds_backup_vault_name == null ? true : length(trimspace(var.rds_backup_vault_name)) > 0
    error_message = "rds_backup_vault_name must be null or a non-empty string."
  }
}

variable "rds_backup_schedule" {
  type        = string
  description = "CRON schedule for AWS Backup (UTC)."
  default     = "cron(0 5 * * ? *)"
}

variable "rds_backup_start_window_minutes" {
  type        = number
  description = "Start window in minutes for AWS Backup jobs."
  default     = 60
}

variable "rds_backup_completion_window_minutes" {
  type        = number
  description = "Completion window in minutes for AWS Backup jobs."
  default     = 180
}

variable "rds_backup_retention_days" {
  type        = number
  description = "Retention period in days for AWS Backup recovery points."
  default     = 35

  validation {
    condition     = var.rds_backup_retention_days > 0
    error_message = "rds_backup_retention_days must be greater than 0."
  }
}

variable "rds_backup_copy_destination_vault_arn" {
  type        = string
  description = "Destination backup vault ARN for cross-region copy (optional)."
  default     = ""

  validation {
    condition     = length(trimspace(var.rds_backup_copy_destination_vault_arn)) == 0 || var.enable_rds_backup
    error_message = "rds_backup_copy_destination_vault_arn requires enable_rds_backup = true."
  }
}

variable "rds_backup_copy_retention_days" {
  type        = number
  description = "Retention period in days for copied recovery points."
  default     = 35

  validation {
    condition     = var.rds_backup_copy_retention_days > 0
    error_message = "rds_backup_copy_retention_days must be greater than 0."
  }
}

variable "enable_dr_backup_vault" {
  type        = bool
  description = "Enable a DR backup vault for cross-region copy targets."
  default     = true
}

variable "dr_backup_vault_name" {
  type        = string
  description = "Optional override for the DR backup vault name."
  default     = null

  validation {
    condition     = var.dr_backup_vault_name == null ? true : length(trimspace(var.dr_backup_vault_name)) > 0
    error_message = "dr_backup_vault_name must be null or a non-empty string."
  }
}

variable "db_deletion_protection" {
  type        = bool
  description = "Enable RDS deletion protection."
  default     = false
}

variable "db_skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on delete."
  default     = true
}

variable "db_final_snapshot_identifier" {
  type        = string
  description = "Final snapshot identifier when skip_final_snapshot is false."
  default     = null
}

variable "db_apply_immediately" {
  type        = bool
  description = "Apply RDS changes immediately."
  default     = true
}

variable "db_log_exports" {
  type        = list(string)
  description = "RDS log exports to CloudWatch."
  default     = ["postgresql"]
}

variable "kms_deletion_window_in_days" {
  type        = number
  description = "KMS deletion window."
  default     = 30
}

variable "prevent_destroy" {
  type        = bool
  description = "Prevent destroying critical resources."
  default     = false
}

variable "enable_alarms" {
  type        = bool
  description = "Enable CloudWatch alarms in this environment."
  default     = false
}

variable "alarm_sns_topic_arn" {
  type        = string
  description = "SNS topic for alarm notifications."
  default     = ""
}

variable "alb_5xx_threshold" {
  type        = number
  description = "ALB 5xx alarm threshold."
  default     = 5
}

variable "alb_latency_p95_threshold" {
  type        = number
  description = "ALB target response time p95 threshold in seconds."
  default     = 1
}

variable "alb_unhealthy_host_threshold" {
  type        = number
  description = "ALB unhealthy host count threshold."
  default     = 1
}

variable "rds_cpu_threshold" {
  type        = number
  description = "RDS CPU alarm threshold."
  default     = 80
}

variable "rds_free_storage_threshold_gb" {
  type        = number
  description = "RDS free storage alarm threshold in GiB."
  default     = 5
}

variable "ecs_cpu_threshold" {
  type        = number
  description = "ECS CPU alarm threshold."
  default     = 80
}

variable "ecs_memory_threshold" {
  type        = number
  description = "ECS memory alarm threshold."
  default     = 80
}

variable "ec2_cpu_threshold" {
  type        = number
  description = "EC2 capacity provider CPU alarm threshold."
  default     = 80
}

variable "alarm_evaluation_periods" {
  type        = number
  description = "Alarm evaluation periods."
  default     = 2
}

variable "alarm_period_seconds" {
  type        = number
  description = "Alarm period in seconds."
  default     = 60
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags to apply."
  default     = {}

  validation {
    condition     = length(setintersection(keys(var.additional_tags), ["Project", "Environment", "Service", "Owner", "CostCenter", "ManagedBy", "Repository"])) == 0
    error_message = "additional_tags must not override Project, Environment, Service, Owner, CostCenter, ManagedBy, or Repository."
  }
}
