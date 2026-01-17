# API Gateway + Lambda Module

This module provisions a small HTTP API (API Gateway v2) backed by a single Lambda function. It is intentionally narrow in scope: two default routes (`GET /health` and `POST /echo`) plus optional extra routes, safe-by-default throttling, and baseline logging.

## Why This Module Exists

- Provide a parallel, opt-in ingress path for small HTTP endpoints.
- Keep API Gateway + Lambda wiring isolated from ECS/Kubernetes concerns.
- Make logging, tracing, and VPC posture explicit and testable.

## Security Posture

- Lambda has no public ingress; when VPC-enabled it uses private subnets with a dedicated security group and no inbound rules.
- Default egress is HTTPS only. If `enable_rds_access = true`, egress is restricted to the RDS security group on port 5432.
- No authentication/authorization is configured by default. Add an authorizer if you need auth.

## Notes

- When running Lambda in a VPC, outbound AWS API calls require a NAT gateway or relevant VPC endpoints.
- `rds_secret_arn` is passed as an environment variable only; retrieving secrets still requires IAM permissions and application logic.
- `enable_xray` enables tracing on the Lambda function only.

## Example

```hcl
module "serverless_api" {
  source = "../../modules/apigw-lambda"

  name_prefix         = local.name_prefix
  environment         = var.environment
  vpc_id              = module.network.vpc_id
  vpc_subnet_ids      = module.network.private_subnet_ids
  log_retention_days  = 7
  enable_xray         = false
  cors_allowed_origins = []

  tags = local.tags
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.7.1 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.28.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_apigatewayv2_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_integration.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_cloudwatch_log_group.api_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.apigw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_security_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.lambda_https_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.lambda_rds_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_iam_policy_document.lambda_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_route_keys"></a> [additional\_route\_keys](#input\_additional\_route\_keys) | Additional API Gateway route keys (for example, GET /info). | `list(string)` | `[]` | no |
| <a name="input_cors_allowed_origins"></a> [cors\_allowed\_origins](#input\_cors\_allowed\_origins) | Allowed CORS origins (empty list disables CORS). | `list(string)` | `[]` | no |
| <a name="input_enable_rds_access"></a> [enable\_rds\_access](#input\_enable\_rds\_access) | Allow Lambda egress to the RDS security group on port 5432. | `bool` | `false` | no |
| <a name="input_enable_xray"></a> [enable\_xray](#input\_enable\_xray) | Enable AWS X-Ray tracing for the Lambda function. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name for labeling (dev or prod). | `string` | n/a | yes |
| <a name="input_log_kms_key_id"></a> [log\_kms\_key\_id](#input\_log\_kms\_key\_id) | Optional KMS key ID for encrypting CloudWatch log groups. | `string` | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log retention in days. | `number` | `30` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used for naming API Gateway and Lambda resources. | `string` | n/a | yes |
| <a name="input_rds_secret_arn"></a> [rds\_secret\_arn](#input\_rds\_secret\_arn) | Optional Secrets Manager ARN for the database (passed as an env var). | `string` | `null` | no |
| <a name="input_rds_security_group_id"></a> [rds\_security\_group\_id](#input\_rds\_security\_group\_id) | RDS security group ID to allow egress when enable\_rds\_access is true. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources in the module. | `map(string)` | n/a | yes |
| <a name="input_throttle_burst_limit"></a> [throttle\_burst\_limit](#input\_throttle\_burst\_limit) | Burst rate limit for the API Gateway default route settings. | `number` | `50` | no |
| <a name="input_throttle_rate_limit"></a> [throttle\_rate\_limit](#input\_throttle\_rate\_limit) | Steady-state rate limit (requests per second) for the API Gateway default route settings. | `number` | `25` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for the Lambda security group. | `string` | `null` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | Additional security group IDs to attach to the Lambda function. | `list(string)` | `[]` | no |
| <a name="input_vpc_subnet_ids"></a> [vpc\_subnet\_ids](#input\_vpc\_subnet\_ids) | Private subnet IDs for Lambda (empty list disables VPC config). | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_endpoint"></a> [api\_endpoint](#output\_api\_endpoint) | API Gateway invoke URL. |
| <a name="output_api_id"></a> [api\_id](#output\_api\_id) | API Gateway ID. |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | Lambda function ARN. |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Lambda function name. |
| <a name="output_lambda_security_group_id"></a> [lambda\_security\_group\_id](#output\_lambda\_security\_group\_id) | Security group ID for the Lambda function (null when VPC is disabled). |
| <a name="output_stage_name"></a> [stage\_name](#output\_stage\_name) | API Gateway stage name. |
<!-- END_TF_DOCS -->
