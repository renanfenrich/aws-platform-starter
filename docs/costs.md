# Cost Notes

## Primary Cost Drivers

- NAT gateways (hourly + data processing)
- RDS instance class and storage
- ECS Fargate vCPU and memory
- ALB hourly + LCU usage

## Cost Controls

- Dev defaults use a single NAT gateway and smaller RDS/ECS sizes.
- Log retention is configurable via variables.
- Multi-AZ is enabled only in production by default.

## Optimization Ideas

- Add VPC endpoints to reduce NAT data charges.
- Use scheduled scaling for non-24/7 workloads.
- Evaluate reserved instances or savings plans for steady usage.
