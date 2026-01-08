output "control_plane_instance_id" {
  description = "EC2 instance ID for the Kubernetes control plane."
  value       = aws_instance.control_plane.id
}

output "control_plane_private_ip" {
  description = "Private IP address of the Kubernetes control plane."
  value       = aws_instance.control_plane.private_ip
}

output "control_plane_security_group_id" {
  description = "Security group ID for the control plane."
  value       = aws_security_group.control_plane.id
}

output "worker_security_group_id" {
  description = "Security group ID for worker nodes."
  value       = aws_security_group.worker.id
}

output "worker_autoscaling_group_name" {
  description = "Auto Scaling group name for Kubernetes workers."
  value       = aws_autoscaling_group.worker.name
}

output "control_plane_instance_profile_arn" {
  description = "IAM instance profile ARN for the control plane."
  value       = aws_iam_instance_profile.control_plane.arn
}

output "worker_instance_profile_arn" {
  description = "IAM instance profile ARN for worker nodes."
  value       = aws_iam_instance_profile.worker.arn
}

output "join_parameter_name" {
  description = "SSM parameter name that stores the kubeadm join command."
  value       = local.join_parameter_name
}

output "join_parameter_kms_key_arn" {
  description = "KMS key ARN used to encrypt the join parameter."
  value       = aws_kms_key.join_parameter.arn
}

output "control_plane_user_data" {
  description = "Rendered user data for the control plane instance."
  value       = local.control_plane_user_data
}

output "worker_user_data" {
  description = "Rendered user data for worker nodes."
  value       = local.worker_user_data
}
