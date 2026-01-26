# RDS Module

This module provisions a single RDS PostgreSQL instance with encryption, a KMS key, a subnet group, and a security group. It uses an RDS-managed master password stored in Secrets Manager. It does not create read replicas or multi-region DR.

## Why This Module Exists

- Centralize database security defaults and parameters.
- Keep application and network modules from owning DB details.
- Make storage, backup, and Multi-AZ decisions explicit inputs.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.28.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_backup_plan.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_selection.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_db_instance.protected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_iam_role.backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.backup_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.restore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.db_protected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_security_group.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.db_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.db_ingress_additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_iam_policy_document.backup_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.backup_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_ingress_security_group_ids"></a> [additional\_ingress\_security\_group\_ids](#input\_additional\_ingress\_security\_group\_ids) | Additional security group IDs allowed to access the database. | `list(string)` | `[]` | no |
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | Allocated storage in GB. | `number` | `20` | no |
| <a name="input_app_security_group_id"></a> [app\_security\_group\_id](#input\_app\_security\_group\_id) | Security group ID for application tasks that need DB access. | `string` | n/a | yes |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Apply changes immediately. | `bool` | `false` | no |
| <a name="input_backup_copy_destination_vault_arn"></a> [backup\_copy\_destination\_vault\_arn](#input\_backup\_copy\_destination\_vault\_arn) | Destination backup vault ARN for cross-region copy (optional). | `string` | `""` | no |
| <a name="input_backup_copy_retention_days"></a> [backup\_copy\_retention\_days](#input\_backup\_copy\_retention\_days) | Retention period in days for copied recovery points. | `number` | `35` | no |
| <a name="input_backup_plan_completion_window_minutes"></a> [backup\_plan\_completion\_window\_minutes](#input\_backup\_plan\_completion\_window\_minutes) | Completion window in minutes for AWS Backup jobs. | `number` | `180` | no |
| <a name="input_backup_plan_schedule"></a> [backup\_plan\_schedule](#input\_backup\_plan\_schedule) | CRON schedule for AWS Backup (UTC). | `string` | `"cron(0 5 * * ? *)"` | no |
| <a name="input_backup_plan_start_window_minutes"></a> [backup\_plan\_start\_window\_minutes](#input\_backup\_plan\_start\_window\_minutes) | Start window in minutes for AWS Backup jobs. | `number` | `60` | no |
| <a name="input_backup_retention_days"></a> [backup\_retention\_days](#input\_backup\_retention\_days) | Retention period in days for AWS Backup recovery points. | `number` | `35` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | Backup retention in days. | `number` | `7` | no |
| <a name="input_backup_vault_name"></a> [backup\_vault\_name](#input\_backup\_vault\_name) | Optional override for the AWS Backup vault name. | `string` | `null` | no |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | Preferred backup window. | `string` | `"03:00-04:00"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Database name. | `string` | n/a | yes |
| <a name="input_db_port"></a> [db\_port](#input\_db\_port) | Database port. | `number` | `5432` | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | Master username for the database. | `string` | n/a | yes |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Enable deletion protection. | `bool` | `true` | no |
| <a name="input_enable_backup_plan"></a> [enable\_backup\_plan](#input\_enable\_backup\_plan) | Enable AWS Backup plan for the database. | `bool` | `false` | no |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled\_cloudwatch\_logs\_exports](#input\_enabled\_cloudwatch\_logs\_exports) | CloudWatch log exports to enable. | `list(string)` | `[]` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | Database engine. | `string` | `"postgres"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Database engine version. | `string` | `"15.4"` | no |
| <a name="input_final_snapshot_identifier"></a> [final\_snapshot\_identifier](#input\_final\_snapshot\_identifier) | Final snapshot identifier to use when skip\_final\_snapshot is false. | `string` | `null` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | RDS instance class. | `string` | `"db.t4g.micro"` | no |
| <a name="input_kms_deletion_window_in_days"></a> [kms\_deletion\_window\_in\_days](#input\_kms\_deletion\_window\_in\_days) | KMS key deletion window. | `number` | `30` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Preferred maintenance window. | `string` | `"Mon:00:00-Mon:03:00"` | no |
| <a name="input_max_allocated_storage"></a> [max\_allocated\_storage](#input\_max\_allocated\_storage) | Maximum storage in GB (autoscaling). | `number` | `100` | no |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | Enable Multi-AZ deployment. | `bool` | `false` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used for naming RDS resources. | `string` | n/a | yes |
| <a name="input_prevent_destroy"></a> [prevent\_destroy](#input\_prevent\_destroy) | Prevent destroying critical database resources. | `bool` | `false` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Private subnet IDs for the database subnet group. | `list(string)` | n/a | yes |
| <a name="input_publicly_accessible"></a> [publicly\_accessible](#input\_publicly\_accessible) | Whether the DB is publicly accessible. | `bool` | `false` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Skip final snapshot on deletion. | `bool` | `false` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | Storage type. | `string` | `"gp3"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to database resources. | `map(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for the database. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_additional_ingress_security_group_ids"></a> [additional\_ingress\_security\_group\_ids](#output\_additional\_ingress\_security\_group\_ids) | Additional security group IDs allowed to access the database. |
| <a name="output_backup_copy_destination_vault_arn"></a> [backup\_copy\_destination\_vault\_arn](#output\_backup\_copy\_destination\_vault\_arn) | Destination backup vault ARN for cross-region copy (null when not set). |
| <a name="output_backup_plan_enabled"></a> [backup\_plan\_enabled](#output\_backup\_plan\_enabled) | Whether AWS Backup is enabled for the database. |
| <a name="output_backup_plan_id"></a> [backup\_plan\_id](#output\_backup\_plan\_id) | AWS Backup plan ID (null when disabled). |
| <a name="output_backup_vault_arn"></a> [backup\_vault\_arn](#output\_backup\_vault\_arn) | AWS Backup vault ARN (null when disabled). |
| <a name="output_backup_vault_name"></a> [backup\_vault\_name](#output\_backup\_vault\_name) | AWS Backup vault name (null when disabled). |
| <a name="output_db_endpoint"></a> [db\_endpoint](#output\_db\_endpoint) | RDS endpoint. |
| <a name="output_db_instance_id"></a> [db\_instance\_id](#output\_db\_instance\_id) | RDS instance identifier. |
| <a name="output_db_port"></a> [db\_port](#output\_db\_port) | RDS port. |
| <a name="output_db_security_group_id"></a> [db\_security\_group\_id](#output\_db\_security\_group\_id) | Security group ID for the database. |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | KMS key ARN used by RDS. |
| <a name="output_master_user_secret_arn"></a> [master\_user\_secret\_arn](#output\_master\_user\_secret\_arn) | Secrets Manager ARN for the RDS master user secret. |
<!-- END_TF_DOCS -->
