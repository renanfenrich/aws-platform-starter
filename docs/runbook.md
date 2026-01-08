# Runbook

This is the short list of steps I actually use when operating this stack.

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

## Scale Compute

- Fargate (`ecs_capacity_mode = "fargate"`): update `desired_count`, `container_cpu`, or `container_memory`, then apply.
- Fargate Spot (`ecs_capacity_mode = "fargate_spot"`): update `desired_count`, `container_cpu`, or `container_memory`, then apply.
- EC2 capacity provider (`ecs_capacity_mode = "ec2"`): update `desired_count`, `ec2_desired_capacity`, `ec2_min_size`, `ec2_max_size`, or `ec2_instance_type`, then apply.

## Handle Fargate Spot Interruptions

- Spot capacity can be reclaimed with short notice. ECS will try to replace tasks using the FARGATE fallback.
- Check ECS service events and task logs to confirm replacement, and increase `desired_count` if you need more buffer.

## Access EC2 Instances

EC2 capacity providers are designed for SSM access. Ensure the instance role has SSM permissions (default) and use Session Manager; no SSH ingress is opened by default.

## Rotate RDS Master Password

RDS manages the master password in Secrets Manager. To rotate:

1) Trigger a rotation in Secrets Manager.
2) Update application credentials if the app caches them.

## Investigate Alarms

- ALB 5xx: check target health, ECS task logs, and recent deploys.
- ECS CPU: scale tasks or increase CPU/memory.
- EC2 CPU: scale the ECS capacity provider Auto Scaling group or move to a larger instance type.
- RDS CPU: scale the instance class or review queries and connections.

## Rollback

Revert the Terraform change (or the commit that introduced it), then apply again. If the container image caused the issue, roll back the image tag and re-apply.

## Delete Dev Environment

```bash
cd environments/dev
terraform destroy -var-file=terraform.tfvars
```

Prod deletions are blocked by `prevent_destroy`.
