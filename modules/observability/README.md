# Observability Module

Creates minimal CloudWatch alarms for ALB, ECS, and RDS.

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
| [aws_cloudwatch_metric_alarm.alb_5xx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ecs_cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.rds_cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_sns_topic_arn"></a> [alarm\_sns\_topic\_arn](#input\_alarm\_sns\_topic\_arn) | SNS topic ARN for alarm notifications (optional). | `string` | `""` | no |
| <a name="input_alb_5xx_threshold"></a> [alb\_5xx\_threshold](#input\_alb\_5xx\_threshold) | Threshold for ALB 5xx target errors. | `number` | `5` | no |
| <a name="input_alb_arn_suffix"></a> [alb\_arn\_suffix](#input\_alb\_arn\_suffix) | ARN suffix of the ALB. | `string` | n/a | yes |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | ECS cluster name. | `string` | n/a | yes |
| <a name="input_ecs_cpu_threshold"></a> [ecs\_cpu\_threshold](#input\_ecs\_cpu\_threshold) | Threshold for ECS CPU utilization. | `number` | `80` | no |
| <a name="input_ecs_service_name"></a> [ecs\_service\_name](#input\_ecs\_service\_name) | ECS service name. | `string` | n/a | yes |
| <a name="input_evaluation_periods"></a> [evaluation\_periods](#input\_evaluation\_periods) | Number of periods for alarm evaluation. | `number` | `2` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used for naming alarms. | `string` | n/a | yes |
| <a name="input_period_seconds"></a> [period\_seconds](#input\_period\_seconds) | Metric evaluation period in seconds. | `number` | `60` | no |
| <a name="input_rds_cpu_threshold"></a> [rds\_cpu\_threshold](#input\_rds\_cpu\_threshold) | Threshold for RDS CPU utilization. | `number` | `80` | no |
| <a name="input_rds_instance_id"></a> [rds\_instance\_id](#input\_rds\_instance\_id) | RDS instance identifier. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to alarm resources. | `map(string)` | `{}` | no |
| <a name="input_target_group_arn_suffix"></a> [target\_group\_arn\_suffix](#input\_target\_group\_arn\_suffix) | ARN suffix of the target group. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_5xx_alarm_name"></a> [alb\_5xx\_alarm\_name](#output\_alb\_5xx\_alarm\_name) | ALB 5xx alarm name. |
| <a name="output_ecs_cpu_alarm_name"></a> [ecs\_cpu\_alarm\_name](#output\_ecs\_cpu\_alarm\_name) | ECS CPU alarm name. |
| <a name="output_rds_cpu_alarm_name"></a> [rds\_cpu\_alarm\_name](#output\_rds\_cpu\_alarm\_name) | RDS CPU alarm name. |
<!-- END_TF_DOCS -->
