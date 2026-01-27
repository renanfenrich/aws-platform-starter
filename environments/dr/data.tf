module "backup_vault" {
  count  = var.enable_dr_backup_vault ? 1 : 0
  source = "../../modules/backup-vault"

  name_prefix                 = local.name_prefix
  vault_name_override         = var.dr_backup_vault_name
  kms_deletion_window_in_days = var.kms_deletion_window_in_days
  tags                        = local.tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix                           = local.name_prefix
  vpc_id                                = module.network.vpc_id
  private_subnet_ids                    = module.network.private_subnet_ids
  app_security_group_id                 = local.platform_is_eks ? module.eks[0].node_security_group_id : local.platform_is_k8s ? module.k8s_ec2_infra[0].worker_security_group_id : local.platform_is_ecs ? aws_security_group.app[0].id : "sg-00000000000000000"
  additional_ingress_security_group_ids = var.enable_serverless_api && var.serverless_api_enable_rds_access ? [module.serverless_api[0].lambda_security_group_id] : []
  db_name                               = var.db_name
  db_username                           = var.db_username
  db_port                               = var.db_port
  engine                                = var.db_engine
  engine_version                        = var.db_engine_version
  instance_class                        = var.db_instance_class
  allocated_storage                     = var.db_allocated_storage
  max_allocated_storage                 = var.db_max_allocated_storage
  storage_type                          = var.db_storage_type
  multi_az                              = var.db_multi_az
  backup_retention_period               = var.db_backup_retention_period
  maintenance_window                    = var.db_maintenance_window
  backup_window                         = var.db_backup_window
  enable_backup_plan                    = var.enable_rds_backup
  backup_vault_name                     = var.rds_backup_vault_name
  backup_plan_schedule                  = var.rds_backup_schedule
  backup_plan_start_window_minutes      = var.rds_backup_start_window_minutes
  backup_plan_completion_window_minutes = var.rds_backup_completion_window_minutes
  backup_retention_days                 = var.rds_backup_retention_days
  backup_copy_destination_vault_arn     = var.rds_backup_copy_destination_vault_arn
  backup_copy_retention_days            = var.rds_backup_copy_retention_days
  deletion_protection                   = var.db_deletion_protection
  skip_final_snapshot                   = var.db_skip_final_snapshot
  final_snapshot_identifier             = var.db_final_snapshot_identifier
  apply_immediately                     = var.db_apply_immediately
  publicly_accessible                   = false
  enabled_cloudwatch_logs_exports       = var.db_log_exports
  kms_deletion_window_in_days           = var.kms_deletion_window_in_days
  prevent_destroy                       = var.prevent_destroy
  tags                                  = local.tags
}
