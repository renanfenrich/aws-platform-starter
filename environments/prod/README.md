# Prod Environment

The prod environment is stability-first by default and enforces stricter safeguards (alarms, flow logs, deletion protection). It uses the same module wiring as dev with higher durability and visibility settings.

## Prerequisites

- Bootstrap applied (`bootstrap/`), and `environments/prod/backend.hcl` wired with `state_bucket_name` and `kms_key_arn`.
- `environments/prod/terraform.tfvars` updated (replace `CHANGE_ME` values like `acm_certificate_arn` and `alb_access_logs_bucket`).
- If cost enforcement is enabled (default), set `TF_VAR_estimated_monthly_cost` before plan/apply.

## Deploy

```bash
export TF_VAR_estimated_monthly_cost=123.45
make plan ENV=prod platform=ecs
make apply ENV=prod platform=ecs
```

## Defaults (from `terraform.tfvars`)

- `platform = "ecs"`
- `ecs_capacity_mode = "fargate"`
- `allow_http = false`
- `alb_enable_access_logs = true`
- `single_nat_gateway = false` (one per AZ)
- `enable_interface_endpoints = true`
- `enable_flow_logs = true`
- `enable_alarms = true`
- `log_retention_in_days = 90`
- `desired_count = 2`
- `db_multi_az = true`
- `db_backup_retention_period = 7`
- `db_deletion_protection = true`
- `db_skip_final_snapshot = false`
- `prevent_destroy = true`

## Guardrails

- `cost_posture` must be `stability_first` in prod.
- `ecs_capacity_mode = "fargate_spot"` requires `allow_spot_in_prod = true`.
- `allow_http` is invalid in prod.
- `enable_alarms` is enforced in prod.
- Budget notifications require `budget_notification_emails`, `budget_sns_topic_arn`, or `alarm_sns_topic_arn`.
- Deploys fail when `enforce_cost_controls = true` and `estimated_monthly_cost` is missing or above the hard limit.

## DR-Related Toggles

- Enable ECR replication: set `ecr_enable_replication = true` and `ecr_replication_regions = ["<dr-region>"]`.
- Enable AWS Backup copy: set `enable_rds_backup = true` and `rds_backup_copy_destination_vault_arn` to the DR vault ARN.

## Destructive Changes

Prod uses `prevent_destroy` and `db_deletion_protection`. To destroy or replace protected resources, you must explicitly disable those safeguards in `terraform.tfvars`, apply, and then proceed with the change.
