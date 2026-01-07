# Runbook

## Deploy (Dev)

```bash
cd environments/dev
terraform init -backend-config=backend.hcl
terraform apply -var-file=terraform.tfvars
```

## Deploy (Prod)

```bash
cd environments/prod
terraform init -backend-config=backend.hcl
terraform apply -var-file=terraform.tfvars
```

## Scale ECS

Update `desired_count`, `container_cpu`, or `container_memory` in the environment tfvars, then apply.

## Rotate RDS Master Password

RDS manages the master password in Secrets Manager. To rotate:

1) Trigger a rotation in Secrets Manager.
2) Update application credentials if required.

## Investigate Alarms

- ALB 5xx: check target health, ECS task logs.
- ECS CPU: scale tasks or increase CPU.
- RDS CPU: scale instance class or review query performance.

## Rollback

Use `terraform apply` with a previous configuration state (or revert commit), then re-apply.

## Delete Dev Environment

```bash
cd environments/dev
terraform destroy -var-file=terraform.tfvars
```

Prod deletions are protected by `prevent_destroy`.
