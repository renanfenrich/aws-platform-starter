# Runbook

This is the short list of steps I actually use when operating this stack.

## Cost Estimate (Required)

Estimate costs before any deploy and pass the number into Terraform:

```bash
INFRACOST_API_KEY=... make cost
```

Capture the estimated monthly cost for the target environment, then export it as `TF_VAR_estimated_monthly_cost`.

## Deploy (Dev)

```bash
export TF_VAR_estimated_monthly_cost=123.45
cd environments/dev
terraform init -backend-config=backend.hcl
terraform apply -var-file=terraform.tfvars
```

## Deploy (Prod)

```bash
export TF_VAR_estimated_monthly_cost=123.45
cd environments/prod
terraform init -backend-config=backend.hcl
terraform apply -var-file=terraform.tfvars
```

## Build and Push an Image to ECR (Manual)

From the environment directory (set `AWS_REGION` to match `aws_region` in your tfvars):

```bash
AWS_REGION=us-east-1
IMAGE_TAG=latest
ECR_REPO=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REPO"
docker build -t demo-app .
docker tag demo-app:latest "${ECR_REPO}:${IMAGE_TAG}"
docker push "${ECR_REPO}:${IMAGE_TAG}"
```

Update `image_tag` (or set `container_image` for a full override) in `terraform.tfvars`, then apply again.

## Production Hardening Toggles

- ALB access logs are enabled in prod by default; set `alb_access_logs_bucket` to the bootstrap output `alb_access_logs_bucket_name`.
- To tighten ALB log delivery, set `alb_access_logs_source_arns` in `bootstrap/terraform.tfvars` after the ALB exists, then re-apply bootstrap.
- WAF is opt-in. Set `alb_enable_waf = true` and `alb_waf_acl_arn` to an existing Web ACL ARN in the environment `terraform.tfvars`.
- Dev flow logs are opt-in. Set `enable_flow_logs = true` in `environments/dev/terraform.tfvars` when needed.

## Notifications

1) Set `alarm_sns_topic_arn` in the environment `terraform.tfvars` to the bootstrap output.
2) If you want email notifications, add addresses to `sns_email_subscriptions` in `bootstrap/terraform.tfvars` and re-apply.
3) Confirm the email subscription in each inbox.

Baseline alarms: ALB 5xx, ECS CPU, EC2 CPU (when enabled), and RDS CPU.

## Budget Alerts

1) Set `budget_notification_emails` or `budget_sns_topic_arn` in each environment `terraform.tfvars`.
2) Confirm email subscriptions or SNS endpoints as required.
3) When a budget warning fires, review the latest cost estimate and recent deploys before adjusting capacity.

## Deploy (Kubernetes Self-Managed)

1) Set `platform = "k8s_self_managed"` in the environment `terraform.tfvars`.
2) Apply the environment as usual.
3) Use the `cluster_access_instructions` output to access the control plane via SSM and apply the demo manifests:

```bash
kubectl apply -f k8s/
```

## Update ECS Image

1) Set `image_tag` (or `container_image`) in the environment `terraform.tfvars`.
2) Apply the environment again.

## Update Kubernetes Image

After applying the environment, use the resolved image output:

```bash
kubectl set image deployment/demo-app app=$(terraform output -raw resolved_container_image) -n demo
```

Kubernetes nodes use the ECR credential helper, so no expiring imagePullSecrets are required.

## Scale Compute

- Fargate (`ecs_capacity_mode = "fargate"`): update `desired_count`, `container_cpu`, or `container_memory`, then apply.
- Fargate Spot (`ecs_capacity_mode = "fargate_spot"`): update `desired_count`, `container_cpu`, or `container_memory`, then apply.
- EC2 capacity provider (`ecs_capacity_mode = "ec2"`): update `desired_count`, `ec2_desired_capacity`, `ec2_min_size`, `ec2_max_size`, or `ec2_instance_type`, then apply.
- Kubernetes workers: update `k8s_worker_desired_capacity`, `k8s_worker_min_size`, `k8s_worker_max_size`, or `k8s_worker_instance_type`, then apply.

## Handle Fargate Spot Interruptions

- Spot capacity can be reclaimed with short notice. ECS will try to replace tasks using the FARGATE fallback.
- Check ECS service events and task logs to confirm replacement, and increase `desired_count` if you need more buffer.

## Access EC2 Instances

EC2 capacity providers are designed for SSM access. Ensure the instance role has SSM permissions (default) and use Session Manager; no SSH ingress is opened by default.

Kubernetes control plane and worker nodes follow the same rule. Use Session Manager to connect to the control plane and run `kubectl` with `/etc/kubernetes/admin.conf`.

## Rotate kubeadm Join Token

Tokens expire by default. On the control plane instance:

```bash
kubeadm token create --print-join-command
aws ssm put-parameter --name <join-parameter-name> --type SecureString --value "<join-command>" --overwrite --region <region>
```

The default parameter name is `/<project>-<environment>/k8s/join-command`, unless overridden with `k8s_join_parameter_name`.

## Rotate RDS Master Password

RDS manages the master password in Secrets Manager. To rotate:

1) Trigger a rotation in Secrets Manager.
2) Update application credentials if the app caches them.

## Investigate Alarms

- ALB 5xx: check target health, ECS task logs, and recent deploys.
- ECS CPU: scale tasks or increase CPU/memory.
- EC2 CPU: scale the EC2 Auto Scaling group (ECS capacity or Kubernetes workers) or move to a larger instance type.
- RDS CPU: scale the instance class or review queries and connections.

## Rollback

Revert the Terraform change (or the commit that introduced it), then apply again. If the container image caused the issue, roll back the image tag and re-apply.

## Delete Dev Environment

```bash
cd environments/dev
terraform destroy -var-file=terraform.tfvars
```

Prod deletions are blocked by `prevent_destroy`.
