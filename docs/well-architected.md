# AWS Well-Architected Mapping

This is a lightweight mapping, not a formal review. It shows how the choices in this repo line up with the pillars and where I stopped on purpose.

## Operational Excellence

What this repo covers:

- Terraform for repeatable infrastructure.
- A short runbook and CI checks for formatting, validation, linting, and security scans.

Where it stops:

- No deployment automation, incident response process, or game days.
- No SLOs or metrics-based release gates.

## Security

What this repo covers:

- Private subnets for compute (ECS or EC2) and RDS.
- TLS termination at the ALB.
- RDS encryption with KMS and managed master password in Secrets Manager.
- Separate task and execution roles with explicit policies, plus an instance role with SSM access in EC2 mode.

Where it stops:

- No WAF or advanced edge controls.
- No centralized log archive or security monitoring stack.

## Reliability

What this repo covers:

- Two AZs for the VPC, ALB, and compute (ECS or EC2 ASG).
- Multi-NAT in prod and a single NAT in dev (explicit trade-off).
- Multi-AZ RDS enabled in prod by default.
- Remote state locking to avoid concurrent apply issues.

Where it stops:

- No multi-region failover or DR strategy.
- No automated failover drills or chaos testing.

## Performance Efficiency

What this repo covers:

- Explicit sizing for ECS tasks or EC2 instance types.
- Basic ALB health checks for service readiness.

Where it stops:

- No autoscaling policies or load testing.
- No performance profiling or tuning beyond defaults.

## Cost Optimization

What this repo covers:

- Single NAT in dev and smaller compute sizes to control spend.
- Configurable log retention and Multi-AZ toggles.

Where it stops:

- No budgets, cost alerts, or anomaly detection.
- No reserved capacity or savings plan strategy.

## Sustainability

What this repo covers:

- Smaller defaults in dev and explicit sizing controls.

Where it stops:

- No scheduled scaling or rightsizing automation.

## Good Enough for This Scope

For a focused example, I consider this baseline sufficient: repeatable IaC, secure defaults, a few alarms, and a clear dev/prod split.

## What I Would Add in a Real Company Environment

- WAF, access logs, and a central logging/metrics platform.
- Deployment automation with safe rollout and rollback strategies.
- Autoscaling and capacity planning based on real load.
- Multi-account isolation, backup policies, and DR planning.
