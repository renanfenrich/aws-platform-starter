# Network Module

This module creates the VPC, public/private subnets across two AZs, routing, an internet gateway, NAT gateways, optional VPC flow logs, and targeted VPC endpoints (S3/DynamoDB gateway plus optional interface endpoints for ECR, CloudWatch Logs, and SSM). It only manages the security group for those interface endpoints.

## Why This Module Exists

- Provide a consistent network baseline for dev and prod.
- Make the NAT cost/resilience trade-off visible with `single_nat_gateway`.
- Keep networking concerns isolated from compute and data.

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
| [aws_cloudwatch_log_group.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.vpc_endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_iam_policy_document.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flow_logs_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for VPC endpoint service names. | `string` | n/a | yes |
| <a name="input_azs"></a> [azs](#input\_azs) | Availability zones to use. | `list(string)` | n/a | yes |
| <a name="input_enable_flow_logs"></a> [enable\_flow\_logs](#input\_enable\_flow\_logs) | Enable VPC flow logs to CloudWatch Logs. | `bool` | `true` | no |
| <a name="input_enable_gateway_endpoints"></a> [enable\_gateway\_endpoints](#input\_enable\_gateway\_endpoints) | Enable gateway VPC endpoints for S3 and DynamoDB. | `bool` | `true` | no |
| <a name="input_enable_interface_endpoints"></a> [enable\_interface\_endpoints](#input\_enable\_interface\_endpoints) | Enable interface VPC endpoints for ECR, CloudWatch Logs, and SSM. | `bool` | `false` | no |
| <a name="input_flow_logs_retention_in_days"></a> [flow\_logs\_retention\_in\_days](#input\_flow\_logs\_retention\_in\_days) | Retention for VPC flow logs in CloudWatch. | `number` | `30` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used for naming network resources. | `string` | n/a | yes |
| <a name="input_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#input\_private\_subnet\_cidrs) | CIDR blocks for private subnets (one per AZ). | `list(string)` | n/a | yes |
| <a name="input_public_subnet_cidrs"></a> [public\_subnet\_cidrs](#input\_public\_subnet\_cidrs) | CIDR blocks for public subnets (one per AZ). | `list(string)` | n/a | yes |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Whether to use a single NAT gateway (cost-saving, less resilient). | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to network resources. | `map(string)` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_flow_logs_log_group_name"></a> [flow\_logs\_log\_group\_name](#output\_flow\_logs\_log\_group\_name) | CloudWatch log group name for VPC flow logs. |
| <a name="output_gateway_endpoint_ids"></a> [gateway\_endpoint\_ids](#output\_gateway\_endpoint\_ids) | IDs of gateway VPC endpoints (S3 and DynamoDB). |
| <a name="output_interface_endpoint_ids"></a> [interface\_endpoint\_ids](#output\_interface\_endpoint\_ids) | IDs of interface VPC endpoints (ECR, CloudWatch Logs, and SSM). |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | IDs of NAT gateways. |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | IDs of the private subnets. |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | IDs of the public subnets. |
| <a name="output_vpc_cidr"></a> [vpc\_cidr](#output\_vpc\_cidr) | CIDR block of the VPC. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC. |
<!-- END_TF_DOCS -->
