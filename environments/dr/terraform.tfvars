project_name        = "aws-platform-starter"
environment         = "dr"
platform            = "ecs"
ecs_capacity_mode   = "fargate"
aws_region          = "us-west-2"
allowed_account_ids = []
service_name        = "platform"
owner               = "platform-team"
cost_center         = "platform"
cost_posture        = "cost_optimized"
allow_spot_in_prod  = false

budget_limit_usd                 = 100
budget_warning_threshold_percent = 85
budget_hard_limit_percent        = 95
budget_notification_emails       = ["platform-alerts@example.com"]
budget_sns_topic_arn             = ""
estimated_monthly_cost           = 0

vpc_cidr                   = "10.30.0.0/16"
public_subnet_cidrs        = ["10.30.0.0/24", "10.30.1.0/24"]
private_subnet_cidrs       = ["10.30.10.0/24", "10.30.11.0/24"]
single_nat_gateway         = true
enable_gateway_endpoints   = true
enable_interface_endpoints = false
enable_flow_logs           = false

alb_enable_public_ingress = false
allow_http                = false
acm_certificate_arn       = ""
alb_ingress_cidrs         = ["0.0.0.0/0"]
alb_deletion_protection   = false
alb_enable_access_logs    = false
alb_access_logs_bucket    = null

# Enable this in the primary region only.
ecr_enable_replication          = false
ecr_replication_regions         = []
ecr_replication_filter_prefixes = []

image_tag         = "latest"
container_port    = 80
container_cpu     = 256
container_memory  = 512
desired_count     = 0
health_check_path = "/"

log_retention_in_days = 7

ec2_instance_type = "t3.micro"
ec2_min_size      = 0
ec2_max_size      = 0

container_user            = "1000"
readonly_root_filesystem  = false
enable_execute_command    = true
enable_container_insights = true

health_check_grace_period_seconds = 60


db_name                               = "appdb"
db_username                           = "appuser"
db_instance_class                     = "db.t4g.micro"
db_multi_az                           = false
db_backup_retention_period            = 1
enable_rds_backup                     = false
rds_backup_copy_destination_vault_arn = ""
enable_dr_backup_vault                = true
dr_backup_vault_name                  = null
db_deletion_protection                = false
db_skip_final_snapshot                = true
db_apply_immediately                  = true

prevent_destroy = false

enable_alarms       = false
alarm_sns_topic_arn = ""

additional_tags = {}
