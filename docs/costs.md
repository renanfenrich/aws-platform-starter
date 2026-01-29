# Cost Notes

This stack is small, but a few services still dominate the bill. The numbers will vary by region and usage, so this is a qualitative guide.

For the end-to-end FinOps flow (estimate → enforce → monitor), see `docs/finops.md`.

## Main Cost Drivers

- NAT gateways (hourly + data processing)
- RDS instance class, storage, and Multi-AZ (when enabled)
- ECS Fargate vCPU/memory (including Spot when selected) or EC2 instance hours when using EC2 capacity providers or Kubernetes nodes
- EKS control plane + managed node groups (when `platform = "eks"`)
- ALB hourly + LCU usage
- API Gateway + Lambda (when `enable_serverless_api = true`)
- CloudWatch logs and alarms
- DR add-ons (when enabled): AWS Backup vault storage, cross-region backup copy, ECR replication, extra ALB/RDS in the DR region

## Cost Levers

- `single_nat_gateway`: reduce NAT hourly cost in dev; prod defaults to one per AZ for resilience.
- `enable_interface_endpoints`: reduces NAT data processing for ECR/Logs/SSM traffic but adds hourly endpoint cost.
- `ecs_capacity_mode`: Fargate Spot lowers compute cost; EC2 capacity can be cheaper when consistently utilized.
- `desired_count`, `container_cpu`, `container_memory`: right-size ECS tasks.
- `db_instance_class`, `db_multi_az`, `db_backup_retention_period`: control RDS cost and resiliency.
- `log_retention_in_days`: trim CloudWatch log storage costs.
- `enable_rds_backup`, `rds_backup_schedule`: tune AWS Backup copy frequency and retention.
- `ecr_enable_replication`: keep image replication scoped to the DR region.
