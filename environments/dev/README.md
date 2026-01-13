# Dev Environment

The dev environment is cost-optimized by default but keeps the same module wiring as prod so you can validate changes without diverging architecture.

## Prerequisites

- Bootstrap applied (`bootstrap/`), and `environments/dev/backend.hcl` wired with `state_bucket_name` and `kms_key_arn`.
- `environments/dev/terraform.tfvars` updated (replace `CHANGE_ME` values).
- If cost enforcement is enabled (default), set `TF_VAR_estimated_monthly_cost` before plan/apply.

## Deploy

```bash
export TF_VAR_estimated_monthly_cost=123.45
make plan ENV=dev platform=ecs
make apply ENV=dev platform=ecs
```

## Defaults (from `terraform.tfvars`)

- `platform = "ecs"`
- `ecs_capacity_mode = "fargate_spot"` (Fargate fallback)
- `allow_http = true`
- `single_nat_gateway = true`
- `enable_interface_endpoints = false`
- `enable_flow_logs = false`
- `enable_alarms = false`
- `log_retention_in_days = 7`
- `db_backup_retention_period = 3`
- `db_deletion_protection = false`
- `db_skip_final_snapshot = true`

## Common Toggles

- Switch to Kubernetes: set `platform = "k8s_self_managed"`.
- Enable alarms: set `enable_alarms = true` and wire `alarm_sns_topic_arn`.
- Enable flow logs: set `enable_flow_logs = true`.
- Enable interface endpoints: set `enable_interface_endpoints = true`.
- Override image: set `container_image` or update `image_tag`.

## Guardrails

- `cost_posture` must be `cost_optimized` in dev.
- `platform` is limited to `ecs` or `k8s_self_managed`; `eks` is reserved and blocked.
- Budget notifications require `budget_notification_emails`, `budget_sns_topic_arn`, or `alarm_sns_topic_arn`.
- Deploys fail when `enforce_cost_controls = true` and `estimated_monthly_cost` is missing or above the hard limit.
