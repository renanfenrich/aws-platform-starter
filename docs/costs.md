# Cost Notes

This stack is small, but a few services still dominate the bill. The numbers will vary by region and usage, so I keep this as a qualitative guide.

## Main Cost Drivers

- NAT gateways (hourly + data processing)
- RDS instance class and storage
- ECS Fargate vCPU/memory (including Spot when selected) or EC2 instance hours when using EC2 capacity providers or Kubernetes nodes
- ALB hourly + LCU usage

## Cost Estimation (Infracost)

I use Infracost for rough deltas across `bootstrap/`, `environments/dev`, and `environments/prod`.

Local run:

```bash
INFRACOST_API_KEY=... make cost
```

Notes:

- `infracost.yml` uses `bootstrap/terraform.tfvars.example` so plans work without local files.
- `make cost` sets `TF_CLI_ARGS_init="-backend=false -input=false"` so Infracost can plan without a real backend.
- If you want real bootstrap values, run:

```bash
infracost breakdown --path bootstrap --terraform-var-file bootstrap/terraform.tfvars
```

- CI needs `INFRACOST_API_KEY` and AWS read-only credentials (data sources still call AWS).

## Current Estimate Snapshot

Snapshot from `make cost` on 2026-01-09 using the default var files in `infracost.yml` (us-east-1). Usage-based charges (NAT data, ALB LCU, CloudWatch logs, RDS backups, S3 storage/requests) are not included.

| Stack | Monthly estimate (USD) |
| --- | --- |
| bootstrap | $1.00 |
| dev | $73.57 |
| prod | $218.24 |
| overall | $292.80 |

Notes:

- Infracost could not price SNS SMS notifications in `bootstrap` (reported as "not found").
- These totals assume the current defaults (Fargate Spot in dev, Multi-AZ RDS in prod, etc.).

## What I Did to Keep Dev Cheap

- Single NAT gateway in dev.
- Smaller compute and RDS defaults.
- Configurable log retention.

## If Cost Became a Priority

- Add VPC endpoints to reduce NAT data charges.
- Use scheduled scaling for non-24/7 workloads.
- Evaluate savings plans or reserved instances for steady usage.
