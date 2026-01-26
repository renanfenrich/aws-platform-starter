# Runbook

This is the short list of steps I actually use when operating this stack.

## Cost Estimate (Required)

Estimate costs before any deploy and pass the number into Terraform:

```bash
INFRACOST_API_KEY=... make cost
```

Capture the estimated monthly cost for the target environment, then export it as `TF_VAR_estimated_monthly_cost`. If you need to bypass enforcement for a one-off estimate, use `enforce_cost_controls = false` (as in `infracost.tfvars`).

## Deploy (Dev)

```bash
export TF_VAR_estimated_monthly_cost=123.45
make plan ENV=dev platform=ecs
make apply ENV=dev platform=ecs
```

## Deploy (Prod)

```bash
export TF_VAR_estimated_monthly_cost=123.45
make plan ENV=prod platform=ecs
make apply ENV=prod platform=ecs
```

## Serverless API (Optional)

1) Set `enable_serverless_api = true` in the environment `terraform.tfvars`.
2) Optional tuning:
   - `serverless_api_log_retention_days`
   - `serverless_api_cors_allowed_origins`
   - `serverless_api_enable_xray`
   - `serverless_api_additional_route_keys`
   - `serverless_api_enable_rds_access` (requires RDS access and a private path to the database)
3) Apply the environment.

`serverless_api_enable_xray` enables tracing on the Lambda function only.

Fetch the endpoint:

```bash
API_ENDPOINT=$(terraform output -raw serverless_api_endpoint)
```

Test the default routes:

```bash
curl "${API_ENDPOINT}/health"
curl -X POST "${API_ENDPOINT}/echo" -H "content-type: application/json" -d '{"ok":true}'
```

Logs land in:

- `/aws/apigateway/<project>-<environment>-serverless-api`
- `/aws/lambda/<project>-<environment>-serverless-api`

When Lambda runs inside private subnets, it still needs NAT or relevant VPC endpoints to reach AWS APIs.

## Enable DNS Records (Optional)

1) Set `enable_dns = true` in the environment `terraform.tfvars`.
2) Provide the hosted zone and record inputs:
   - `dns_hosted_zone_id`
   - `dns_domain_name` (no trailing dot)
   - `dns_record_name` (empty string for apex)
   - Optional: `dns_create_www_alias`, `dns_create_aaaa`
3) Apply the environment.

Verify the record resolves:

```bash
PUBLIC_FQDN=$(terraform output -raw public_fqdn)
dig +short "${PUBLIC_FQDN}"
nslookup "${PUBLIC_FQDN}"
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
- Dev interface endpoints are opt-in. Set `enable_interface_endpoints = true` in `environments/dev/terraform.tfvars` if you want ECR/Logs/SSM traffic to stay inside the VPC.

## Notifications

1) Set `enable_alarms = true` in dev if you want alarms; prod enforces alarms on.
2) Set `alarm_sns_topic_arn` in the environment `terraform.tfvars` to the bootstrap output.
3) If you want email notifications, add addresses to `sns_email_subscriptions` in `bootstrap/terraform.tfvars` and re-apply.
4) Confirm the email subscription in each inbox.

Baseline alarms: ALB 5xx, ALB latency p95, ALB unhealthy hosts, ECS CPU, ECS memory, ECS desired vs running, EC2 CPU (when enabled), RDS CPU, and RDS free storage.

## Dashboards

Each environment creates a CloudWatch dashboard named `<project>-<environment>-observability` with ALB, compute, and RDS metrics.

## Logs

- ECS logs land in `/aws/ecs/<project>-<environment>` and honor `log_retention_in_days`.
- Self-managed Kubernetes logs land in `/aws/k8s/<project>-<environment>` using the same retention.
- RDS exports error logs only by default (`db_log_exports = ["postgresql"]`); slow query logs are opt-in.

## Budget Alerts

1) Set `budget_notification_emails` or `budget_sns_topic_arn` in each environment `terraform.tfvars` (or rely on `alarm_sns_topic_arn`).
2) Confirm email subscriptions or SNS endpoints as required.
3) When a budget warning fires, review the latest cost estimate and recent deploys before adjusting capacity.

## Deploy (Kubernetes Self-Managed)

1) Set `platform = "k8s_self_managed"` in the environment `terraform.tfvars`.
2) Apply the environment as usual; when using the Makefile, pass `platform=k8s_self_managed` so it does not override the tfvars value.
3) Use the `cluster_access_instructions` output to access the control plane via SSM and apply the demo manifests:

```bash
kubectl apply -k k8s/overlays/dev
```

Prod uses the prod overlay:

```bash
kubectl apply -k k8s/overlays/prod
```

The control plane bootstrap installs flannel and ingress-nginx. The ALB forwards to the ingress controller NodePort (`k8s_ingress_nodeport`).

Verify basics:

```bash
kubectl get pods -n demo
kubectl get hpa -n demo
kubectl get netpol -n demo
```

If HPA reports `Unknown`, install metrics-server in the cluster first.

## Deploy (EKS)

1) Set `platform = "eks"` in the environment `terraform.tfvars`.
2) Apply the environment as usual; when using the Makefile, pass `platform=eks` so it does not override the tfvars value.
3) Use the `cluster_access_instructions` output to access the admin runner via SSM and run kubectl.

The EKS API endpoint is private by default. If you need public endpoint access, set `eks_endpoint_public_access = true` and restrict `eks_endpoint_public_access_cidrs` to trusted IPs.

Once you are connected to the admin runner:

```bash
eks-kubeconfig
kubectl get nodes
```

Install ingress-nginx and pin the NodePort to the Terraform-configured value (default `30080`). Replace `30080` if you set `eks_ingress_nodeport` (or use `terraform output -raw k8s_ingress_nodeport` from the environment directory):

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/aws/deploy.yaml
kubectl -n ingress-nginx patch svc ingress-nginx-controller -p "{\"spec\": {\"type\": \"NodePort\", \"ports\": [{\"name\": \"http\", \"port\": 80, \"protocol\": \"TCP\", \"targetPort\": \"http\", \"nodePort\": 30080}]}}"
```

Then apply the demo manifests (dev shown):

```bash
kubectl apply -k k8s/overlays/dev
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
- EKS nodes: update `eks_node_desired_capacity`, `eks_node_min_size`, `eks_node_max_size`, or `eks_node_instance_type`, then apply.

## Handle Fargate Spot Interruptions

- Spot capacity can be reclaimed with short notice. ECS will try to replace tasks using the FARGATE fallback.
- Check ECS service events and task logs to confirm replacement, and increase `desired_count` if you need more buffer.

## Access EC2 Instances

EC2 capacity providers are designed for SSM access. Ensure the instance role has SSM permissions (default) and use Session Manager; no SSH ingress is opened by default.

Kubernetes control plane and worker nodes follow the same rule. EKS nodes and the admin runner also use Session Manager; no SSH ingress is opened by default.

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

## RDS Restore Procedure

RDS does not restore in place. Always restore a snapshot into a new instance, validate it, and then cut over.

1) Identify the instance and snapshot:
   - `DB_ID=$(terraform output -raw rds_instance_id)`
   - Automated backups: `aws rds describe-db-snapshots --db-instance-identifier "$DB_ID" --snapshot-type automated --query 'DBSnapshots[].[DBSnapshotIdentifier,SnapshotCreateTime]' --output table`
   - Final snapshots (prod default): `terraform output -raw rds_final_snapshot_arn_pattern`

2) Restore to a new instance:
   - `RESTORE_ID="${DB_ID}-restore-$(date +%Y%m%d%H%M)"`
   - `aws rds restore-db-instance-from-db-snapshot --db-instance-identifier "$RESTORE_ID" --db-snapshot-identifier "$SNAPSHOT_ID"`
   - `aws rds wait db-instance-available --db-instance-identifier "$RESTORE_ID"`

3) Fetch the new endpoint and cut over:
   - `RESTORE_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier "$RESTORE_ID" --query 'DBInstances[0].Endpoint.Address' --output text)`
   - Update application configuration/secrets to use the restored endpoint and verify application health.

4) Reconcile with Terraform (optional but recommended):
   - If you need Terraform to manage the restored instance, plan a controlled replacement so the identifier matches `<project>-<environment>-db`, then import the instance into state.
   - Dev (`prevent_destroy = false`): `terraform import module.rds.aws_db_instance.this[0] "<db-instance-identifier>"`
   - Prod (`prevent_destroy = true`): `terraform import module.rds.aws_db_instance.protected[0] "<db-instance-identifier>"`

Warnings:
- `db_deletion_protection` and `prevent_destroy` block destructive actions; only disable them when you are ready to replace the instance, then re-enable after recovery.
- Keep `db_skip_final_snapshot = false` in prod so a final snapshot is captured before any deletion.
- Do not assume Terraform can restore the existing instance in place; it requires a new instance and an import.

## Disaster Recovery (Pilot-Light)

Use this when the primary region is unavailable or you must fail over for incident response.

### Preconditions

- DR environment exists and can be planned (`environments/dr`).
- ECR replication is enabled in the primary environment (optional but recommended).
- AWS Backup copy to the DR vault is enabled if you want cross-region recovery points.
- DNS cutover plan is ready (Route 53 failover or manual CNAME).

### Declare DR Checklist

1) Confirm primary region outage scope and estimated duration.
2) Freeze non-essential changes in the primary environment.
3) Notify stakeholders of expected RTO/RPO.
4) Run readiness checks:

```bash
scripts/dr-readiness.sh environments/prod environments/dr
```

### Restore Database in DR

1) Identify a recovery point or snapshot in the primary region.
2) Restore into the DR region:
   - AWS Backup: restore the latest recovery point into a new DB instance.
   - Snapshot copy: restore the latest copied snapshot.
3) Capture the new endpoint and secret ARN.
4) Update application configuration/secrets in the DR region.

### Scale Compute in DR

1) Update `environments/dr/terraform.tfvars`:
   - `desired_count` for ECS, or
   - `k8s_worker_*` / `eks_node_*` for Kubernetes.
2) Apply:

```bash
export TF_VAR_estimated_monthly_cost=123.45
make apply ENV=dr platform=ecs
```

### Enable Public Ingress and Cutover Traffic

1) Set `alb_enable_public_ingress = true` and provide a DR ACM cert.
2) Apply `environments/dr`.
3) Cut over DNS:
   - Route 53 failover record, or
   - Manual CNAME change.

### Validate

- Smoke tests against the DR endpoint.
- Check ALB target health and ECS task status.
- Verify RDS connectivity and application logs.

### Rollback Path

- Revert DNS to primary.
- Scale DR compute back to 0.
- Disable public ingress (`alb_enable_public_ingress = false`).

### Post-Incident Reconciliation

- Compare Terraform state vs. actual DR resources (import if needed).
- Document incident timeline and data loss (actual RPO).
- Re-enable primary and plan a controlled failback.

## Investigate Alarms

- ALB 5xx: check target health, application logs, and recent deploys.
- ALB latency p95: check upstream dependencies (ECS tasks or Kubernetes nodes) and the database; scale compute if CPU/memory is saturated.
- ALB unhealthy hosts: check target group health checks, task/node health, and security group rules.
- ECS CPU: scale tasks or increase CPU/memory.
- ECS memory: increase task memory or reduce in-process caching.
- ECS desired vs running: check ECS service events, deployment progress, and capacity provider headroom.
- EC2 CPU: scale the Auto Scaling group (ECS capacity or Kubernetes workers) or move to a larger instance type.
- RDS CPU: scale the instance class or review queries and connections.
- RDS free storage: increase allocated storage or reduce data footprint.

## Rollback

Revert the Terraform change (or the commit that introduced it), then apply again. If the container image caused the issue, roll back the image tag and re-apply.

## Delete Dev Environment

```bash
cd environments/dev
terraform destroy -var-file=terraform.tfvars
```

Prod deletions are blocked by `prevent_destroy` and `db_deletion_protection`.
