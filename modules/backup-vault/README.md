# Backup Vault Module

This module creates an AWS Backup vault encrypted with a customer-managed KMS key. It is intended for DR copy targets or environment-specific backup storage.

## Why This Module Exists

- Keep backup vault creation explicit and environment-scoped.
- Enforce KMS encryption for recovery points.
- Provide a reusable destination vault for cross-region copies.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_backup_vault.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_kms_alias.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.vault_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kms_deletion_window_in_days"></a> [kms\_deletion\_window\_in\_days](#input\_kms\_deletion\_window\_in\_days) | KMS key deletion window (days) for backup vault encryption. | `number` | `30` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used for naming the backup vault. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to backup vault resources. | `map(string)` | n/a | yes |
| <a name="input_vault_name_override"></a> [vault\_name\_override](#input\_vault\_name\_override) | Optional backup vault name override. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | KMS key ARN used to encrypt the backup vault. |
| <a name="output_vault_arn"></a> [vault\_arn](#output\_vault\_arn) | ARN of the AWS Backup vault. |
| <a name="output_vault_name"></a> [vault\_name](#output\_vault\_name) | Name of the AWS Backup vault. |
<!-- END_TF_DOCS -->
