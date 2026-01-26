project_name        = "aws-platform-starter"
environment         = "prod"
platform            = "ecs"
ecs_capacity_mode   = "fargate"
aws_region          = "us-east-1"
allowed_account_ids = []
service_name        = "platform"
owner               = "platform-team"
cost_center         = "platform"
cost_posture        = "stability_first"
allow_spot_in_prod  = false

budget_limit_usd                 = 400
budget_warning_threshold_percent = 75
budget_hard_limit_percent        = 90
budget_notification_emails       = ["platform-alerts@example.com"]
budget_sns_topic_arn             = ""

vpc_cidr                   = "10.20.0.0/16"
public_subnet_cidrs        = ["10.20.0.0/24", "10.20.1.0/24"]
private_subnet_cidrs       = ["10.20.10.0/24", "10.20.11.0/24"]
single_nat_gateway         = false
enable_gateway_endpoints   = true
enable_interface_endpoints = true
enable_flow_logs           = true

alb_enable_public_ingress = true
allow_http                = false
acm_certificate_arn       = "CHANGE_ME"
alb_ingress_cidrs         = ["0.0.0.0/0"]
alb_deletion_protection   = true
alb_enable_access_logs    = true
alb_access_logs_bucket    = "CHANGE_ME"

enable_dns           = false
dns_hosted_zone_id   = ""
dns_domain_name      = ""
dns_record_name      = ""
dns_create_www_alias = false
dns_create_aaaa      = true

ecr_enable_replication          = false
ecr_replication_regions         = []
ecr_replication_filter_prefixes = []

image_tag         = "latest"
container_port    = 80
container_cpu     = 512
container_memory  = 1024
desired_count     = 2
health_check_path = "/"

log_retention_in_days = 90

ec2_instance_type = "t3.small"
ec2_min_size      = 2
ec2_max_size      = 2

container_user            = "1000"
readonly_root_filesystem  = false
enable_execute_command    = true
enable_container_insights = true

health_check_grace_period_seconds = 60


db_name                               = "appdb"
db_username                           = "appuser"
db_instance_class                     = "db.t4g.medium"
db_multi_az                           = true
db_backup_retention_period            = 7
enable_rds_backup                     = false
rds_backup_copy_destination_vault_arn = ""
db_deletion_protection                = true
db_skip_final_snapshot                = false
db_apply_immediately                  = false

prevent_destroy = true

alarm_sns_topic_arn = ""

additional_tags = {}
