# Interview Talk Track - Project 1: AWS Platform Terraform

## Recruiter summary

- I built a small AWS platform in Terraform that mirrors how I start real services: VPC, ALB, ECS Fargate or EC2, RDS, and a few alarms.
- It includes dev/prod environments and a bootstrap step for remote state.
- CI runs fmt/validate/tflint/tfsec/terraform-docs/terraform test as a quality gate.
- The scope is intentionally limited so the trade-offs are visible.

## Technical overview

- Bootstrap creates the S3 bucket and DynamoDB table for remote state, with versioning, encryption, and public access blocks.
- Environments (dev/prod) compose the modules and apply default tags.
- Network module provisions a two-AZ VPC, public/private subnets, IGW, NAT, and optional flow logs.
- ALB module provides HTTPS by default (HTTP optional in dev), restrictive security groups, and target group health checks.
- ECS module runs Fargate tasks in private subnets with separate IAM roles and CloudWatch logs.
- EC2 module runs instances in private subnets with an Auto Scaling group, launch template, and SSM-enabled instance role.
- RDS module deploys encrypted Postgres with an RDS-managed master password stored in Secrets Manager.
- Observability module adds CloudWatch alarms for ALB 5xx, ECS CPU, and RDS CPU.

## Key decisions and trade-offs

- ECS by default to keep the example focused, with EC2 available when host control is needed.
- Two AZs as a baseline; single NAT in dev to reduce cost.
- HTTPS enforced by default; HTTP only allowed in dev for speed.
- Managed RDS master password to keep secrets out of Terraform state.
- Minimal alarms to avoid noise; I expect teams to add app-specific signals.

## Failure scenarios

- ALB 5xx spike: check target health, ECS logs, and recent deploys; roll back the image or Terraform change.
- ECS CPU saturation: increase task size or desired count; add autoscaling if needed.
- EC2 CPU saturation: increase instance size or scale the Auto Scaling group.
- RDS CPU or storage pressure: scale the instance or storage; review queries and connection counts.
- NAT outage (dev single NAT): accept reduced resilience; prod uses multi-NAT.
- State lock contention: verify the DynamoDB lock and team workflow; force unlock only with coordination.

## What was intentionally not built

- WAF, IDS/IPS, or advanced edge security controls.
- Blue/green deployments or ECS autoscaling policies.
- Centralized logging or metrics beyond baseline CloudWatch alarms.
- VPC endpoints, private registries, or multi-account orchestration.

## Well-Architected alignment

- Operational Excellence: IaC, a runbook, and CI quality checks.
- Security: private subnets, TLS by default, KMS encryption, Secrets Manager.
- Reliability: multi-AZ networking, remote state locking, health checks.
- Performance Efficiency: explicit Fargate sizing and ALB health checks.
- Cost Optimization: single NAT in dev, size defaults, configurable log retention.
- Sustainability: smaller dev defaults with clear sizing knobs.

## Common interview questions

- "Why Fargate?" -> I wanted to keep ops overhead low and focus on infrastructure wiring.
- "How do you keep secrets out of state?" -> RDS manages the master password and stores it in Secrets Manager; ECS reads the secret at runtime.
- "How would you harden this for production?" -> Add WAF, access logs, VPC endpoints, backup policies, and tighter ingress controls.
- "What would you add for scale?" -> ECS autoscaling, ALB target tracking, and DB read replicas if the workload needs them.
