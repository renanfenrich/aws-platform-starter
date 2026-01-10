# ECS EC2 Capacity Module

This module provisions an ECS capacity provider backed by an EC2 Auto Scaling group. It uses ECS-optimized AMIs, private subnets, and SSM-enabled instance roles.

## Why This Module Exists

- Provide EC2-backed ECS capacity when host-level control is required.
- Keep container instances private with SSM access and IMDSv2 enforcement.

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
| [aws_autoscaling_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_ecs_capacity_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_capacity_provider) | resource |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_iam_policy_document.instance_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_ssm_parameter.ecs_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | Optional AMI ID override for ECS container instances. | `string` | `null` | no |
| <a name="input_capacity_provider_max_scaling_step_size"></a> [capacity\_provider\_max\_scaling\_step\_size](#input\_capacity\_provider\_max\_scaling\_step\_size) | Maximum scaling step size for ECS managed scaling. | `number` | `1000` | no |
| <a name="input_capacity_provider_min_scaling_step_size"></a> [capacity\_provider\_min\_scaling\_step\_size](#input\_capacity\_provider\_min\_scaling\_step\_size) | Minimum scaling step size for ECS managed scaling. | `number` | `1` | no |
| <a name="input_capacity_provider_name"></a> [capacity\_provider\_name](#input\_capacity\_provider\_name) | Name for the ECS capacity provider. | `string` | n/a | yes |
| <a name="input_capacity_provider_target_capacity"></a> [capacity\_provider\_target\_capacity](#input\_capacity\_provider\_target\_capacity) | Target capacity percentage for ECS managed scaling. | `number` | `100` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | ECS cluster name for container instances. | `string` | n/a | yes |
| <a name="input_desired_capacity"></a> [desired\_capacity](#input\_desired\_capacity) | Desired size of the Auto Scaling group. | `number` | n/a | yes |
| <a name="input_ecs_ami_ssm_parameter"></a> [ecs\_ami\_ssm\_parameter](#input\_ecs\_ami\_ssm\_parameter) | SSM parameter path for the ECS-optimized AMI. | `string` | `"/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"` | no |
| <a name="input_enable_detailed_monitoring"></a> [enable\_detailed\_monitoring](#input\_enable\_detailed\_monitoring) | Enable detailed monitoring for EC2 instances. | `bool` | `true` | no |
| <a name="input_enable_managed_scaling"></a> [enable\_managed\_scaling](#input\_enable\_managed\_scaling) | Enable ECS managed scaling for the capacity provider. | `bool` | `true` | no |
| <a name="input_enable_managed_termination_protection"></a> [enable\_managed\_termination\_protection](#input\_enable\_managed\_termination\_protection) | Enable ECS managed termination protection. | `bool` | `true` | no |
| <a name="input_enable_ssm"></a> [enable\_ssm](#input\_enable\_ssm) | Attach the SSM managed policy for Session Manager access. | `bool` | `true` | no |
| <a name="input_health_check_grace_period_seconds"></a> [health\_check\_grace\_period\_seconds](#input\_health\_check\_grace\_period\_seconds) | Grace period before Auto Scaling health checks start. | `number` | `60` | no |
| <a name="input_instance_role_policy_arns"></a> [instance\_role\_policy\_arns](#input\_instance\_role\_policy\_arns) | Additional policy ARNs to attach to the instance role. | `list(string)` | `[]` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type for container instances. | `string` | n/a | yes |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum size of the Auto Scaling group. | `number` | n/a | yes |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum size of the Auto Scaling group. | `number` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used for naming EC2 capacity resources. | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Private subnet IDs for the Auto Scaling group. | `list(string)` | n/a | yes |
| <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id) | Security group ID attached to the EC2 instances. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to EC2 capacity resources. | `map(string)` | n/a | yes |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Additional user data appended after ECS cluster configuration. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_name"></a> [autoscaling\_group\_name](#output\_autoscaling\_group\_name) | Auto Scaling group name for ECS capacity. |
| <a name="output_capacity_provider_name"></a> [capacity\_provider\_name](#output\_capacity\_provider\_name) | ECS capacity provider name. |
| <a name="output_instance_role_arn"></a> [instance\_role\_arn](#output\_instance\_role\_arn) | IAM role ARN for ECS container instances. |
<!-- END_TF_DOCS -->
