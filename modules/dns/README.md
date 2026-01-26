# DNS Module

This module manages optional Route53 alias records for the public ALB. It only creates records when explicitly enabled and requires an existing hosted zone ID.

## Why This Module Exists

- Keep DNS changes opt-in and scoped to a known hosted zone.
- Support apex and subdomain aliases without taking ownership of hosted zones.
- Provide a stable public endpoint name when DNS is enabled.

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
| [aws_route53_record.primary_a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.primary_aaaa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.www_a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.www_aaaa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_dns_name"></a> [alb\_dns\_name](#input\_alb\_dns\_name) | ALB DNS name for Route53 alias targets. | `string` | `""` | no |
| <a name="input_alb_zone_id"></a> [alb\_zone\_id](#input\_alb\_zone\_id) | Route53 zone ID for the ALB alias target. | `string` | `""` | no |
| <a name="input_create_aaaa"></a> [create\_aaaa](#input\_create\_aaaa) | Create AAAA alias records for IPv6. | `bool` | `true` | no |
| <a name="input_create_apex_alias"></a> [create\_apex\_alias](#input\_create\_apex\_alias) | Create the apex alias record when record\_name is empty. | `bool` | `true` | no |
| <a name="input_create_www_alias"></a> [create\_www\_alias](#input\_create\_www\_alias) | Create www alias records when record\_name is empty. | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Base domain name for the hosted zone (example.com). | `string` | `""` | no |
| <a name="input_enable_dns"></a> [enable\_dns](#input\_enable\_dns) | Enable Route53 record management. | `bool` | `false` | no |
| <a name="input_hosted_zone_id"></a> [hosted\_zone\_id](#input\_hosted\_zone\_id) | Route53 hosted zone ID for record creation. | `string` | `""` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used for naming resources in the parent stack. | `string` | n/a | yes |
| <a name="input_record_name"></a> [record\_name](#input\_record\_name) | Subdomain label for the record (empty string for apex). | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags from the parent stack (Route53 records do not support tags). | `map(string)` | n/a | yes |
| <a name="input_target_type"></a> [target\_type](#input\_target\_type) | Target type for the DNS records. | `string` | `"alb"` | no |
| <a name="input_ttl"></a> [ttl](#input\_ttl) | TTL for non-alias records (unused for ALB alias targets). | `number` | `300` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dns_enabled"></a> [dns\_enabled](#output\_dns\_enabled) | Whether DNS record management is enabled. |
| <a name="output_dns_fqdn"></a> [dns\_fqdn](#output\_dns\_fqdn) | Primary DNS name created by this module (null when no records are created). |
| <a name="output_dns_records"></a> [dns\_records](#output\_dns\_records) | Record names and types created by this module. |
<!-- END_TF_DOCS -->
