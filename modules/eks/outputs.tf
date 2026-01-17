output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID for the EKS control plane."
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID for EKS worker nodes."
  value       = aws_security_group.node.id
}

output "node_group_autoscaling_group_name" {
  description = "Auto Scaling group name for the EKS managed node group."
  value       = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name
}

output "cluster_access_instructions" {
  description = "How to access the EKS cluster via the admin runner."
  value = var.enable_admin_runner ? (
    <<-EOT
      aws ssm start-session --target ${aws_instance.admin_runner[0].id} --region ${data.aws_region.current.id}
      eks-kubeconfig
      kubectl get nodes
    EOT
  ) : "Admin runner is disabled (enable_admin_runner = false). Provide a private access path to the EKS API endpoint to use kubectl."
}
