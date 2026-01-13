# Cost Notes

This stack is small, but a few services still dominate the bill. The numbers will vary by region and usage, so this is a qualitative guide.

For the end-to-end FinOps flow (estimate → enforce → monitor), see `docs/finops.md`.

## Main Cost Drivers

- NAT gateways (hourly + data processing)
- RDS instance class, storage, and Multi-AZ (when enabled)
- ECS Fargate vCPU/memory (including Spot when selected) or EC2 instance hours when using EC2 capacity providers or Kubernetes nodes
- ALB hourly + LCU usage
- CloudWatch logs and alarms

## Cost Estimation (Infracost)

I use Infracost for rough deltas across `bootstrap/`, `environments/dev`, and `environments/prod`.

Local run:

```bash
INFRACOST_API_KEY=... make cost
```

Notes:

- `infracost.yml` uses `bootstrap/terraform.tfvars.example` and each environment's `terraform.tfvars` + `infracost.tfvars`.
- `infracost.tfvars` disables deploy-time enforcement and sets `estimated_monthly_cost = 0` so plans remain deterministic.
- `make cost` uses backendless init/plan; data sources still call AWS, so read-only AWS credentials are required.
- After estimating, set `TF_VAR_estimated_monthly_cost` before running plan/apply with enforcement enabled.

## Cost Levers

- `single_nat_gateway`: reduce NAT hourly cost in dev; prod defaults to one per AZ for resilience.
- `enable_interface_endpoints`: reduces NAT data processing for ECR/Logs/SSM traffic but adds hourly endpoint cost.
- `ecs_capacity_mode`: Fargate Spot lowers compute cost; EC2 capacity can be cheaper when consistently utilized.
- `desired_count`, `container_cpu`, `container_memory`: right-size ECS tasks.
- `db_instance_class`, `db_multi_az`, `db_backup_retention_period`: control RDS cost and resiliency.
- `log_retention_in_days`: trim CloudWatch log storage costs.
