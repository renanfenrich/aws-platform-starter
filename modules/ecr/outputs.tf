output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.this.arn
}

output "repository_name" {
  description = "Name of the ECR repository."
  value       = aws_ecr_repository.this.name
}

output "repository_url" {
  description = "URL of the ECR repository."
  value       = aws_ecr_repository.this.repository_url
}

output "image_tag_mutability" {
  description = "Image tag mutability setting for the repository."
  value       = aws_ecr_repository.this.image_tag_mutability
}

output "scan_on_push" {
  description = "Whether image scanning is enabled on push."
  value       = aws_ecr_repository.this.image_scanning_configuration[0].scan_on_push
}

output "replication_enabled" {
  description = "Whether ECR replication is enabled for this repository."
  value       = var.enable_replication
}

output "replication_regions" {
  description = "Destination regions configured for ECR replication."
  value       = var.replication_regions
}

output "replication_filters" {
  description = "Repository filters used for ECR replication."
  value       = local.replication_filters
}
