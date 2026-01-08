project_name        = "aws-production-platform"
environment         = "dev"
compute_mode        = "ecs"
aws_region          = "us-east-1"
allowed_account_ids = []

vpc_cidr             = "10.10.0.0/16"
public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]
single_nat_gateway   = true

allow_http              = true
acm_certificate_arn     = "CHANGE_ME"
alb_ingress_cidrs       = ["0.0.0.0/0"]
alb_deletion_protection = false

container_image   = "public.ecr.aws/nginx/nginx:latest"
container_port    = 80
container_cpu     = 256
container_memory  = 512
desired_count     = 1
health_check_path = "/"

log_retention_in_days = 30

ec2_instance_type = "t3.micro"
ec2_min_size      = 1
ec2_max_size      = 1

container_user            = "1000"
readonly_root_filesystem  = false
enable_execute_command    = true
enable_container_insights = true

health_check_grace_period_seconds = 60


db_name                    = "appdb"
db_username                = "appuser"
db_instance_class          = "db.t4g.micro"
db_multi_az                = false
db_backup_retention_period = 3
db_deletion_protection     = false
db_skip_final_snapshot     = true
db_apply_immediately       = true

alarm_sns_topic_arn = ""

additional_tags = {}
