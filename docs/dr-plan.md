# Disaster Recovery Plan (Pilot-Light)

This repo now supports an opt-in, cross-region **pilot-light** DR model. The intent is to keep a minimal footprint in a secondary region and make recovery steps explicit and reproducible.

## DR Targets (Defaults)

These are conservative defaults for a small single-service stack:

- **RTO (Recovery Time Objective):** 4 hours
- **RPO (Recovery Point Objective):** 24 hours

Drivers:
- **RDS automated backups** are local, but cross-region recovery depends on the optional AWS Backup copy schedule (daily by default).
- **ECR replication** is near real-time when enabled.
- **S3 state replication** is optional and near real-time when enabled.

You can tighten these objectives by increasing backup frequency or moving to a warm-standby pattern.

## Scope and Assumptions

- Single service behind an ALB with a PostgreSQL database.
- Pilot-light means **zero/low compute by default** and **no public ingress** until cutover.
- DR is **opt-in per environment** and should not affect dev/prod costs unless enabled.
- This repo does **not** manage multi-account routing or org-wide guardrails.

## What “DR Implemented” Means Here

- A dedicated `environments/dr` stack can be planned/applied independently.
- A documented, repeatable recovery procedure exists (see Runbook + steps below).
- Data/replication prerequisites are codified and optional via explicit flags.

## Reference Architecture

### Primary Region (Active)
- VPC, ALB, ECS/EKS/K8s compute, RDS PostgreSQL
- Optional ECR replication (to DR)
- Optional AWS Backup plan (with cross-region copy)

### DR Region (Pilot-Light)
- VPC, ALB, ECR repo, RDS (single-AZ) with minimal sizing
- Compute desired count = 0 (or node group size = 0)
- **Public ALB listeners disabled by default**
- Optional DR backup vault for cross-region copy targets

## Data Strategy

### RDS (Primary → DR)
Two supported paths:

1) **AWS Backup (recommended, opt-in)**
   - Enable `enable_rds_backup = true` in the primary environment.
   - Provide `rds_backup_copy_destination_vault_arn` from the DR environment output (`dr_backup_vault_arn`).
   - Backups are scheduled via `rds_backup_schedule` (default daily).

2) **Snapshot restore (manual)**
   - Use `aws rds describe-db-snapshots` in the primary region.
   - Restore into the DR region during a declared incident.

### ECR (Primary → DR)
- Enable `ecr_enable_replication = true` in the primary environment.
- Set `ecr_replication_regions = ["<dr-region>"]`.
- Replication config is registry-wide; **enable it in only one environment per region** (typically prod).

### S3 (State) Replication (Optional)
- Bootstrap supports **optional** cross-region replication for the Terraform state bucket.
- This is **off by default** to avoid surprise cost.
- Replication is scoped to state only; logs are not replicated by default.

## Traffic Cutover (DNS)

DNS is intentionally out of scope for this repo. If you manage Route 53 in Terraform, use a failover record set and health check. Example stub:

```hcl
resource "aws_route53_health_check" "primary" {
  fqdn              = var.primary_alb_dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
}

resource "aws_route53_record" "app_primary" {
  zone_id = var.zone_id
  name    = var.dns_name
  type    = "A"

  set_identifier = "primary"
  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = var.primary_alb_dns_name
    zone_id                = var.primary_alb_zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.primary.id
}

resource "aws_route53_record" "app_dr" {
  zone_id = var.zone_id
  name    = var.dns_name
  type    = "A"

  set_identifier = "dr"
  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = var.dr_alb_dns_name
    zone_id                = var.dr_alb_zone_id
    evaluate_target_health = false
  }
}
```

## Secrets and Encryption

- **RDS master secrets** are regional (Secrets Manager). Replication is not automatic.
- For DR, restore RDS and re-point application configuration to the new secret ARN.
- **KMS keys are regional.** Cross-region backup copies require a destination vault key in the DR region.
- The DR backup vault module creates a CMK with a backup-service-friendly policy.

## Operational Procedure (High-Level)

1) **Declare DR**
   - Confirm primary region outage scope.
   - Freeze non-essential changes in primary.

2) **Verify prerequisites**
   - Run `scripts/dr-readiness.sh` to confirm replication and backups.

3) **Restore database in DR**
   - Restore from AWS Backup recovery point or snapshot copy.
   - Capture the new endpoint and Secrets Manager ARN.

4) **Scale DR compute**
   - Set `desired_count` (ECS) or increase K8s/EKS node sizes.
   - Apply `environments/dr`.

5) **Enable public ingress**
   - Set `alb_enable_public_ingress = true` and provide a DR ACM cert.
   - Apply `environments/dr`.

6) **Cut over traffic**
   - Update DNS (Route 53 failover or manual CNAME).

7) **Validate**
   - Run smoke tests, verify logs/alarms.

8) **Rollback (if needed)**
   - Revert DNS and scale DR back down.

## Cost/FinOps Considerations

When DR is disabled: **no cost impact**.

When DR is enabled:
- Base costs: VPC, NAT (single), ALB, minimal RDS, and a KMS key for the DR backup vault.
- ECR replication and AWS Backup copy add data transfer + storage costs.
- Compute is the main variable cost when scaling up during an incident.

Note: `infracost.yml` currently covers bootstrap/dev/prod only; add the DR environment if you want estimates in CI.

## Optional Upgrades (Not Default)

- **Warm standby:** keep minimal compute running (desired_count >= 1) and higher RDS class.
- **Active-active:** multi-region writes with application-level data replication and global traffic routing.

These modes are intentionally out of scope for this repo but can be layered on later.
