# DR Environment

The DR environment is a pilot-light stack meant for cross-region recovery. It mirrors prod module wiring but defaults to low/zero capacity and no public ingress until you explicitly cut over.

## Prerequisites

- Bootstrap applied for the DR region, and `environments/dr/backend.hcl` wired with `state_bucket_name` and `kms_key_arn`.
- `environments/dr/terraform.tfvars` updated (replace `CHANGE_ME` values).
- If cost enforcement is enabled (default), set `TF_VAR_estimated_monthly_cost` before plan/apply.

## Deploy

```bash
export TF_VAR_estimated_monthly_cost=123.45
make plan ENV=dr platform=ecs
make apply ENV=dr platform=ecs
```

## Defaults (from `terraform.tfvars`)

- `platform = "ecs"`
- `ecs_capacity_mode = "fargate"`
- `desired_count = 0`
- `alb_enable_public_ingress = false`
- `allow_http = false`
- `single_nat_gateway = true`
- `enable_interface_endpoints = false`
- `enable_flow_logs = false`
- `enable_alarms = false`
- `log_retention_in_days = 7`
- `db_multi_az = false`
- `db_backup_retention_period = 1`
- `db_deletion_protection = false`
- `db_skip_final_snapshot = true`
- `prevent_destroy = false`

## Common Toggles

- Enable public ingress during cutover: set `alb_enable_public_ingress = true` and provide `acm_certificate_arn`.
- Scale compute up: set `desired_count` (ECS) or `k8s_worker_*`/`eks_node_*` values when switching platforms.
- Enable RDS backup copy from primary: set `enable_rds_backup = true` in the primary environment and pass the DR vault ARN.

## Guardrails

- `environment` must be `dr`.
- `cost_posture` must be `cost_optimized`.
- `allow_http` is always false.
- `desired_count` defaults to 0; scaling up is explicit.
