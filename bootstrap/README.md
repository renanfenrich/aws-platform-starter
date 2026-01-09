# Bootstrap

I keep bootstrap separate to avoid circular dependencies. This stack creates the baseline account resources that other environments depend on.

## What it creates

- S3 bucket for Terraform state (versioning, SSE-KMS, access logging, public access blocks).
- S3 bucket for access logs (versioning, SSE-KMS).
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

4) Enable native S3 locking by setting `use_lockfile = true` in each backend config.

5) Wire notifications by setting `alarm_sns_topic_arn` in the environment `terraform.tfvars`.

6) If you enabled ACM, use `acm_certificate_arn` for `acm_certificate_arn` in the environment `terraform.tfvars`.

## Notes

- The state bucket has versioning, CMK encryption, access logging, and public access blocking enabled.
- State locking uses the native S3 lock file (`use_lockfile = true`) instead of DynamoDB.
- `prevent_destroy` is enforced in configuration to protect state assets.
- Access logs go to `${state_bucket_name}-logs` unless `log_bucket_name` is set.
- The log bucket does not log itself to avoid recursive logging.
- SNS topic name is `${project_name}-${environment}-${region_short}-infra-alerts`.
- SNS email subscriptions require confirmation from each recipient.
- Route53 hosted zones are not created here; supply an existing hosted zone ID to enable ACM DNS validation.

## Destroy (use caution)

State storage is intentionally protected. To destroy:

1) Temporarily set `prevent_destroy = false` in `bootstrap/main.tf`.
2) If you need to remove the buckets, set `force_destroy = true`.
3) Apply, then destroy.

Do not destroy the state bucket without migrating state.
