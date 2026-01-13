# Observability Module

This module adds a minimal set of CloudWatch alarms for ALB 5xx/latency/unhealthy hosts, ECS CPU/memory/capacity, EC2 CPU (when enabled), and RDS CPU/free storage. It can wire alarms to an SNS topic if you provide one and always creates a per-environment CloudWatch dashboard. It does not add tracing or a centralized logging platform.

## Why This Module Exists

- Keep baseline alarms in one place without bloating the core stack.
- Make it easy to swap in a richer observability setup later.
- Avoid burying alarm logic inside unrelated modules.

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
| [aws_cloudwatch_dashboard.observability](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_metric_alarm.alb_5xx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.alb_latency_p95](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.alb_unhealthy_hosts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ec2_cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ecs_capacity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ecs_cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ecs_memory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.rds_cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.rds_free_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_sns_topic_arn"></a> [alarm\_sns\_topic\_arn](#input\_alarm\_sns\_topic\_arn) | SNS topic ARN for alarm notifications (optional). | `string` | `""` | no |
| <a name="input_alb_5xx_threshold"></a> [alb\_5xx\_threshold](#input\_alb\_5xx\_threshold) | Threshold for ALB 5xx target errors. | `number` | `5` | no |
| <a name="input_alb_arn_suffix"></a> [alb\_arn\_suffix](#input\_alb\_arn\_suffix) | ARN suffix of the ALB. | `string` | n/a | yes |
| <a name="input_alb_latency_p95_threshold"></a> [alb\_latency\_p95\_threshold](#input\_alb\_latency\_p95\_threshold) | Threshold in seconds for ALB target response time p95. | `number` | `1` | no |
| <a name="input_alb_unhealthy_host_threshold"></a> [alb\_unhealthy\_host\_threshold](#input\_alb\_unhealthy\_host\_threshold) | Threshold for ALB unhealthy host count. | `number` | `1` | no |
| <a name="input_ec2_asg_name"></a> [ec2\_asg\_name](#input\_ec2\_asg\_name) | EC2 Auto Scaling group name for capacity provider alarms. | `string` | `""` | no |
| <a name="input_ec2_cpu_threshold"></a> [ec2\_cpu\_threshold](#input\_ec2\_cpu\_threshold) | Threshold for EC2 CPU utilization. | `number` | `80` | no |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | ECS cluster name for ECS service alarms. | `string` | `""` | no |
| <a name="input_ecs_cpu_threshold"></a> [ecs\_cpu\_threshold](#input\_ecs\_cpu\_threshold) | Threshold for ECS CPU utilization. | `number` | `80` | no |
| <a name="input_ecs_memory_threshold"></a> [ecs\_memory\_threshold](#input\_ecs\_memory\_threshold) | Threshold for ECS memory utilization. | `number` | `80` | no |
| <a name="input_ecs_service_name"></a> [ecs\_service\_name](#input\_ecs\_service\_name) | ECS service name for ECS service alarms. | `string` | `""` | no |
| <a name="input_enable_alarms"></a> [enable\_alarms](#input\_enable\_alarms) | Enable CloudWatch alarms for this environment. | `bool` | `true` | no |
| <a name="input_enable_ec2_cpu_alarm"></a> [enable\_ec2\_cpu\_alarm](#input\_enable\_ec2\_cpu\_alarm) | Enable EC2 CPU alarm for EC2-based compute. | `bool` | `false` | no |
| <a name="input_enable_ecs_cpu_alarm"></a> [enable\_ecs\_cpu\_alarm](#input\_enable\_ecs\_cpu\_alarm) | Enable ECS service alarms (CPU, memory, capacity). | `bool` | `true` | no |
| <a name="input_evaluation_periods"></a> [evaluation\_periods](#input\_evaluation\_periods) | Number of periods for alarm evaluation. | `number` | `2` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used for naming alarms. | `string` | n/a | yes |
| <a name="input_period_seconds"></a> [period\_seconds](#input\_period\_seconds) | Metric evaluation period in seconds. | `number` | `60` | no |
| <a name="input_rds_cpu_threshold"></a> [rds\_cpu\_threshold](#input\_rds\_cpu\_threshold) | Threshold for RDS CPU utilization. | `number` | `80` | no |
| <a name="input_rds_free_storage_threshold_gb"></a> [rds\_free\_storage\_threshold\_gb](#input\_rds\_free\_storage\_threshold\_gb) | Threshold in GiB for RDS free storage space. | `number` | `5` | no |
| <a name="input_rds_instance_id"></a> [rds\_instance\_id](#input\_rds\_instance\_id) | RDS instance identifier. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to alarm resources. | `map(string)` | n/a | yes |
| <a name="input_target_group_arn_suffix"></a> [target\_group\_arn\_suffix](#input\_target\_group\_arn\_suffix) | ARN suffix of the target group. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_5xx_alarm_name"></a> [alb\_5xx\_alarm\_name](#output\_alb\_5xx\_alarm\_name) | ALB 5xx alarm name. |
| <a name="output_alb_latency_p95_alarm_name"></a> [alb\_latency\_p95\_alarm\_name](#output\_alb\_latency\_p95\_alarm\_name) | ALB target response time p95 alarm name. |
| <a name="output_alb_unhealthy_hosts_alarm_name"></a> [alb\_unhealthy\_hosts\_alarm\_name](#output\_alb\_unhealthy\_hosts\_alarm\_name) | ALB unhealthy host count alarm name. |
| <a name="output_dashboard_name"></a> [dashboard\_name](#output\_dashboard\_name) | CloudWatch dashboard name. |
| <a name="output_ec2_cpu_alarm_name"></a> [ec2\_cpu\_alarm\_name](#output\_ec2\_cpu\_alarm\_name) | EC2 CPU alarm name. |
| <a name="output_ecs_capacity_alarm_name"></a> [ecs\_capacity\_alarm\_name](#output\_ecs\_capacity\_alarm\_name) | ECS desired vs running alarm name. |
| <a name="output_ecs_cpu_alarm_name"></a> [ecs\_cpu\_alarm\_name](#output\_ecs\_cpu\_alarm\_name) | ECS CPU alarm name. |
| <a name="output_ecs_memory_alarm_name"></a> [ecs\_memory\_alarm\_name](#output\_ecs\_memory\_alarm\_name) | ECS memory alarm name. |
| <a name="output_rds_cpu_alarm_name"></a> [rds\_cpu\_alarm\_name](#output\_rds\_cpu\_alarm\_name) | RDS CPU alarm name. |
| <a name="output_rds_free_storage_alarm_name"></a> [rds\_free\_storage\_alarm\_name](#output\_rds\_free\_storage\_alarm\_name) | RDS free storage alarm name. |
<!-- END_TF_DOCS -->
