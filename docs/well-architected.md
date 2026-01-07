# AWS Well-Architected Mapping

## Operational Excellence

- Infrastructure as code with Terraform.
- Standardized runbook (`docs/runbook.md`).
- CI checks for formatting, validation, linting, and security.

## Security

- RDS encryption with KMS.
- Secrets Manager integration for database credentials.
- Least-privilege IAM roles for ECS.
- Private subnets for ECS and RDS.

## Reliability

- Multi-AZ subnets for ALB, ECS, and RDS.
- Remote state with locking to prevent state corruption.
- Health checks and minimal alarms.

## Performance Efficiency

- Fargate for right-sized compute.
- Target group health checks and autoscaling-ready design.

## Cost Optimization

- Single NAT gateway in dev to reduce cost.
- Instance size defaults tuned for dev vs prod.
- Optional log retention controls.

## Sustainability

- Smaller defaults in dev to reduce waste.
- Ability to right-size compute and storage.
