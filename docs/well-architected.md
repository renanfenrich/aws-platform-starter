# AWS Well-Architected Mapping

This is a lightweight mapping, not a formal review. It shows how the choices in this repo line up with the pillars and where I stopped on purpose.

## Operational Excellence

What this repo covers:

- Terraform for repeatable infrastructure.
- A short runbook and CI checks for formatting, validation, linting, docs, security scans, and tests.
- Kubernetes access and bootstrap steps via SSM for the self-managed option.

Where it stops:

- No deployment automation, incident response process, or game days.
- No SLOs or metrics-based release gates.

## Security

What this repo covers:

- Private subnets for ECS tasks (Fargate, Fargate Spot, or EC2 capacity providers) and RDS.
- Private subnets for Kubernetes control plane and worker nodes, with no public SSH ingress.
- TLS termination at the ALB with optional WAF association.
- RDS encryption with KMS and managed master password in Secrets Manager.
- Separate task and execution roles with explicit policies, plus instance roles with SSM access for EC2 capacity providers.
- Kubeadm join command stored in SSM Parameter Store and encrypted with a CMK.

Where it stops:

- No managed WAF rule sets or bot protection.
- No centralized log archive or security monitoring stack.

## Reliability

What this repo covers:

- Two AZs for the VPC, ALB, and compute (ECS or Kubernetes workers).
- Multi-NAT in prod and a single NAT in dev (explicit trade-off).
- Multi-AZ RDS enabled in prod by default.
- Remote state locking to avoid concurrent apply issues.
- Pilot-light DR stack with manual cutover and opt-in cross-region copy/replication (`docs/dr-plan.md`).

Where it stops:

- No automated multi-region failover or active-active routing; DR remains manual.
- No automated failover drills or chaos testing.
- No explicit buffering beyond the Fargate fallback when using Fargate Spot.
- Self-managed Kubernetes uses a single control plane instance (no HA control plane).

## Performance Efficiency

What this repo covers:

- Explicit sizing for ECS tasks and EC2 instance types when using EC2 capacity providers or Kubernetes nodes.
- Optional ECS autoscaling (CPU target tracking) for simple elasticity.
- Basic ALB health checks for service readiness.

Where it stops:

- No load testing or performance profiling beyond defaults.
- No advanced autoscaling policies or request-based scaling.

## Cost Optimization

What this repo covers:

- Cost posture enforcement (dev = cost optimized, prod = stability first).
- Infracost estimates + deploy-time cost enforcement.
- AWS Budgets per environment with warning and forecasted thresholds.
- Dev defaults optimized for lower spend (single NAT, Fargate Spot, smaller instance sizes).

Where it stops:

- No reserved capacity or savings plan strategy.
- No automated rightsizing or scheduled scaling.

## Sustainability

What this repo covers:

- Smaller defaults in dev and explicit sizing controls.
- Spot-first defaults in dev to avoid always-on overprovisioning.

Where it stops:

- No scheduled scaling or automated idle-time shutdowns.

## Good Enough for This Scope

For a focused example, I consider this baseline sufficient: repeatable IaC, secure defaults, a few alarms, and a clear dev/prod split.

## What I Would Add in a Real Company Environment

- Managed WAF rules, centralized log/metrics pipelines, and tracing.
- Deployment automation with safe rollout and rollback strategies.
- Autoscaling and capacity planning based on real load.
- Multi-account isolation, backup policies, and DR planning.
