# Bootstrap

I keep bootstrap separate to avoid circular dependencies. This stack creates the baseline account resources that other environments depend on.

## What it creates

- S3 bucket for Terraform state (versioning, SSE-KMS, access logging, public access blocks).
- S3 bucket for access logs (versioning, SSE-KMS).
- S3 bucket for ALB access logs (SSE-KMS, lifecycle rules, restricted delivery policy).
- KMS key for state, logs, and SNS encryption.
- SNS topic for infrastructure notifications (optional email subscriptions).
- Optional ACM certificate with DNS validation when a hosted zone ID is supplied.

## Usage

1) Create a local `terraform.tfvars` (use the example as a base):

```bash
cp bootstrap/terraform.tfvars.example bootstrap/terraform.tfvars
```

2) Initialize and apply:

```bash
terraform -chdir=bootstrap init
terraform -chdir=bootstrap plan -var-file=terraform.tfvars
terraform -chdir=bootstrap apply -var-file=terraform.tfvars
```

3) Update `environments/dev/backend.hcl` and `environments/prod/backend.hcl` using the outputs:

- `state_bucket_name`
- `kms_key_arn`

4) Ensure native S3 locking is enabled by keeping `use_lockfile = true` in each backend config (the examples already include it).

5) Wire notifications by setting `alarm_sns_topic_arn` in the environment `terraform.tfvars` to the `sns_topic_arn` output.

6) If you enabled ACM, use `acm_certificate_arn` for `acm_certificate_arn` in the environment `terraform.tfvars`.

7) For ALB access logs, set `alb_access_logs_bucket` in the prod environment `terraform.tfvars` to the `alb_access_logs_bucket_name` output.

## Notes

- The state bucket has versioning, CMK encryption, access logging, and public access blocking enabled.
- State locking uses the native S3 lock file (`use_lockfile = true`) instead of DynamoDB.
- `prevent_destroy` is enforced in configuration to protect state assets.
- Access logs go to `${state_bucket_name}-logs` unless `log_bucket_name` is set.
- The log bucket does not log itself to avoid recursive logging.
- The ALB access log bucket name defaults to `<project>-<environment>-<account>-<region>-alb-logs` unless overridden.
- Restrict ALB log delivery to specific load balancers by setting `alb_access_logs_source_arns` after the ALB exists.
- SNS topic name is `${project_name}-${environment}-${region_short}-infra-alerts`.
- SNS email subscriptions require confirmation from each recipient.
- Route53 hosted zones are not created here; supply an existing hosted zone ID to enable ACM DNS validation.

## Destroy (use caution)

State storage is intentionally protected. To destroy:

1) Temporarily set `prevent_destroy = false` in `bootstrap/main.tf`.
2) If you need to remove the buckets, set `force_destroy = true`.
3) Apply, then destroy.

Do not destroy the state bucket without migrating state.
