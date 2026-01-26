# ECR Module

This module provisions a single ECR repository for the application image in each environment. It enables immutable tags and scan-on-push by default, and applies a lifecycle policy to expire older untagged images.

## Why This Module Exists

- Keep image storage explicit and environment-scoped.
- Provide safe defaults (immutability, scanning, encryption).
- Avoid coupling compute modules to registry creation.

## Lifecycle Policy

The default lifecycle policy keeps the most recent N untagged images (`lifecycle_keep_last`) and expires older untagged images. Tagged images are unaffected.

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
| [aws_ecr_lifecycle_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_replication_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_replication_configuration) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_replication"></a> [enable\_replication](#input\_enable\_replication) | Enable cross-region ECR replication for this repository. | `bool` | `false` | no |
| <a name="input_immutable_tags"></a> [immutable\_tags](#input\_immutable\_tags) | Whether to enforce immutable image tags. | `bool` | `true` | no |
| <a name="input_lifecycle_keep_last"></a> [lifecycle\_keep\_last](#input\_lifecycle\_keep\_last) | Number of untagged images to keep. | `number` | `30` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used for naming the ECR repository. | `string` | n/a | yes |
| <a name="input_replication_filter_prefixes"></a> [replication\_filter\_prefixes](#input\_replication\_filter\_prefixes) | Repository name prefixes to replicate (defaults to the repository name). | `list(string)` | `[]` | no |
| <a name="input_replication_regions"></a> [replication\_regions](#input\_replication\_regions) | Destination regions for ECR replication. | `list(string)` | `[]` | no |
| <a name="input_repository_name_override"></a> [repository\_name\_override](#input\_repository\_name\_override) | Optional repository name override. | `string` | `null` | no |
| <a name="input_scan_on_push"></a> [scan\_on\_push](#input\_scan\_on\_push) | Enable image scanning on push. | `bool` | `true` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | Service name used in the repository name. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the ECR repository. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_image_tag_mutability"></a> [image\_tag\_mutability](#output\_image\_tag\_mutability) | Image tag mutability setting for the repository. |
| <a name="output_replication_enabled"></a> [replication\_enabled](#output\_replication\_enabled) | Whether ECR replication is enabled for this repository. |
| <a name="output_replication_filters"></a> [replication\_filters](#output\_replication\_filters) | Repository filters used for ECR replication. |
| <a name="output_replication_regions"></a> [replication\_regions](#output\_replication\_regions) | Destination regions configured for ECR replication. |
| <a name="output_repository_arn"></a> [repository\_arn](#output\_repository\_arn) | ARN of the ECR repository. |
| <a name="output_repository_name"></a> [repository\_name](#output\_repository\_name) | Name of the ECR repository. |
| <a name="output_repository_url"></a> [repository\_url](#output\_repository\_url) | URL of the ECR repository. |
| <a name="output_scan_on_push"></a> [scan\_on\_push](#output\_scan\_on\_push) | Whether image scanning is enabled on push. |
<!-- END_TF_DOCS -->
