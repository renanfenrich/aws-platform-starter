# Kubernetes EC2 Infrastructure Module

This module provisions a minimal self-managed Kubernetes foundation on EC2: a single control plane instance, a worker Auto Scaling group, and supporting IAM, KMS, and security groups. It renders bootstrap scripts for kubeadm, installs flannel and ingress-nginx, and publishes the join command to SSM.

## Why This Module Exists

- Provide a deterministic self-managed Kubernetes option alongside ECS.
- Keep nodes private, SSM-enabled (optional), and behind an ALB for ingress.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
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
| [aws_autoscaling_group.worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_cloudwatch_log_group.k8s_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_instance_profile.control_plane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_instance_profile.worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.control_plane_ssm_join](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.k8s_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.worker_ssm_join](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.control_plane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.control_plane_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.control_plane_ecr_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.control_plane_extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.control_plane_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.control_plane_ssm_join](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.worker_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.worker_ecr_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.worker_extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.worker_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.worker_ssm_join](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.control_plane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_kms_alias.join_parameter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.join_parameter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_launch_template.worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.control_plane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.control_plane_egress_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.control_plane_egress_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.control_plane_from_workers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.control_plane_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.worker_egress_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.worker_egress_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.worker_from_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.worker_from_control_plane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.worker_from_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.control_plane_ssm_join](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.instance_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.k8s_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.worker_ssm_join](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_ssm_parameter.k8s_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_security_group_id"></a> [alb\_security\_group\_id](#input\_alb\_security\_group\_id) | ALB security group ID to allow ingress to the NodePort. | `string` | n/a | yes |
| <a name="input_alb_target_group_arn"></a> [alb\_target\_group\_arn](#input\_alb\_target\_group\_arn) | ALB target group ARN to attach to the worker Auto Scaling group. | `string` | n/a | yes |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | Optional AMI ID override for Kubernetes nodes. | `string` | `null` | no |
| <a name="input_ami_ssm_parameter"></a> [ami\_ssm\_parameter](#input\_ami\_ssm\_parameter) | SSM parameter path for the Kubernetes node AMI. | `string` | `"/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Kubernetes cluster name used by kubeadm. | `string` | n/a | yes |
| <a name="input_control_plane_instance_type"></a> [control\_plane\_instance\_type](#input\_control\_plane\_instance\_type) | EC2 instance type for the Kubernetes control plane. | `string` | n/a | yes |
| <a name="input_enable_detailed_monitoring"></a> [enable\_detailed\_monitoring](#input\_enable\_detailed\_monitoring) | Enable detailed monitoring for Kubernetes nodes. | `bool` | `true` | no |
| <a name="input_enable_ssm"></a> [enable\_ssm](#input\_enable\_ssm) | Attach SSM permissions for node access and bootstrap automation. | `bool` | `true` | no |
| <a name="input_health_check_grace_period_seconds"></a> [health\_check\_grace\_period\_seconds](#input\_health\_check\_grace\_period\_seconds) | Grace period before Auto Scaling health checks start. | `number` | `300` | no |
| <a name="input_ingress_nodeport"></a> [ingress\_nodeport](#input\_ingress\_nodeport) | NodePort used by the ingress controller for ALB traffic. | `number` | `30080` | no |
| <a name="input_instance_role_policy_arns"></a> [instance\_role\_policy\_arns](#input\_instance\_role\_policy\_arns) | Additional policy ARNs to attach to Kubernetes instance roles. | `list(string)` | `[]` | no |
| <a name="input_join_parameter_name"></a> [join\_parameter\_name](#input\_join\_parameter\_name) | Optional SSM parameter name for the kubeadm join command. | `string` | `""` | no |
| <a name="input_k8s_version"></a> [k8s\_version](#input\_k8s\_version) | Kubernetes version for kubeadm (ex: 1.29.2). | `string` | `"1.29.2"` | no |
| <a name="input_kms_deletion_window_in_days"></a> [kms\_deletion\_window\_in\_days](#input\_kms\_deletion\_window\_in\_days) | KMS deletion window for the join parameter key. | `number` | `30` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | Retention for Kubernetes application logs in CloudWatch Logs. | `number` | `30` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used for naming Kubernetes EC2 resources. | `string` | n/a | yes |
| <a name="input_pod_cidr"></a> [pod\_cidr](#input\_pod\_cidr) | CIDR for Kubernetes pods. | `string` | `"10.244.0.0/16"` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Private subnet IDs for control plane and worker nodes. | `list(string)` | n/a | yes |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | CIDR for Kubernetes services. | `string` | `"10.96.0.0/12"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to Kubernetes resources. | `map(string)` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC CIDR block for security group rules. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for Kubernetes resources. | `string` | n/a | yes |
| <a name="input_worker_desired_capacity"></a> [worker\_desired\_capacity](#input\_worker\_desired\_capacity) | Desired size of the worker Auto Scaling group. | `number` | n/a | yes |
| <a name="input_worker_instance_type"></a> [worker\_instance\_type](#input\_worker\_instance\_type) | EC2 instance type for Kubernetes worker nodes. | `string` | n/a | yes |
| <a name="input_worker_max_size"></a> [worker\_max\_size](#input\_worker\_max\_size) | Maximum size of the worker Auto Scaling group. | `number` | n/a | yes |
| <a name="input_worker_min_size"></a> [worker\_min\_size](#input\_worker\_min\_size) | Minimum size of the worker Auto Scaling group. | `number` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_control_plane_instance_id"></a> [control\_plane\_instance\_id](#output\_control\_plane\_instance\_id) | EC2 instance ID for the Kubernetes control plane. |
| <a name="output_control_plane_instance_profile_arn"></a> [control\_plane\_instance\_profile\_arn](#output\_control\_plane\_instance\_profile\_arn) | IAM instance profile ARN for the control plane. |
| <a name="output_control_plane_private_ip"></a> [control\_plane\_private\_ip](#output\_control\_plane\_private\_ip) | Private IP address of the Kubernetes control plane. |
| <a name="output_control_plane_security_group_id"></a> [control\_plane\_security\_group\_id](#output\_control\_plane\_security\_group\_id) | Security group ID for the control plane. |
| <a name="output_control_plane_user_data"></a> [control\_plane\_user\_data](#output\_control\_plane\_user\_data) | Rendered user data for the control plane instance. |
| <a name="output_join_parameter_kms_key_arn"></a> [join\_parameter\_kms\_key\_arn](#output\_join\_parameter\_kms\_key\_arn) | KMS key ARN used to encrypt the join parameter. |
| <a name="output_join_parameter_name"></a> [join\_parameter\_name](#output\_join\_parameter\_name) | SSM parameter name that stores the kubeadm join command. |
| <a name="output_worker_autoscaling_group_name"></a> [worker\_autoscaling\_group\_name](#output\_worker\_autoscaling\_group\_name) | Auto Scaling group name for Kubernetes workers. |
| <a name="output_worker_instance_profile_arn"></a> [worker\_instance\_profile\_arn](#output\_worker\_instance\_profile\_arn) | IAM instance profile ARN for worker nodes. |
| <a name="output_worker_security_group_id"></a> [worker\_security\_group\_id](#output\_worker\_security\_group\_id) | Security group ID for worker nodes. |
| <a name="output_worker_user_data"></a> [worker\_user\_data](#output\_worker\_user\_data) | Rendered user data for worker nodes. |
<!-- END_TF_DOCS -->
