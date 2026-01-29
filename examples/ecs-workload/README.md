# ECS Workload Wiring (Example)

This is an optional, non-production example. It is illustrative only.

## What this demonstrates

- An ECS service wired to the existing ALB target group
- Plain container environment variables
- Secrets Manager injection using the existing RDS master secret
- Health check path alignment by reading the target group configuration
- Image wiring from the environment ECR repository output

## What this does NOT do

- Build or push container images (see docs/runbook.md for the ECR workflow)
- Create new ALBs, target groups, DNS records, or certificates
- Add new IAM policies or secrets
- Provide CI/CD or application source code

## How it relates to the platform

- This root module consumes the environment state (dev or prod) to reuse the ALB, ECR repository, ECS cluster, and RDS secret.
- It creates a second ECS service in the existing cluster and target group.
- `desired_count` defaults to 0 so it will not schedule tasks until you opt in.

## Usage (optional)

1) Deploy the platform with `platform = "ecs"`.
2) Create a local `terraform.tfvars` in this directory with values that match your environment:

```hcl
project_name = "platform"
environment  = "dev"
service_name = "platform"
owner        = "platform-team"
cost_center  = "shared"

aws_region   = "us-east-1"
state_bucket = "your-terraform-state-bucket"
state_key    = "platform/dev/terraform.tfstate"
state_region = "us-east-1"

image_tag     = "latest"
desired_count = 0
```

3) Initialize and apply:

```bash
terraform init
terraform apply
```

Notes:
- The ALB health check path is read from the target group and passed into the container as `ALB_HEALTHCHECK_PATH`. Ensure your image serves a 200 on that path.
- The example uses the existing ECS execution role. If you inject a different secret, you must grant access to that role (out of scope for this example).
