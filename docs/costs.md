# Cost Notes

This stack is small, but a few services still dominate the bill. The numbers will vary by region and usage, so I keep this as a qualitative guide.

## Main Cost Drivers

- NAT gateways (hourly + data processing)
- RDS instance class and storage
- ECS Fargate vCPU/memory (including Spot when selected) or EC2 instance hours when using EC2 capacity providers
- ALB hourly + LCU usage

## What I Did to Keep Dev Cheap

- Single NAT gateway in dev.
- Smaller compute and RDS defaults.
- Configurable log retention.

## If Cost Became a Priority

- Add VPC endpoints to reduce NAT data charges.
- Use scheduled scaling for non-24/7 workloads.
- Evaluate savings plans or reserved instances for steady usage.
