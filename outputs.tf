# ----------------------------------------------------------------------
# EKS Cluster Outputs
# ----------------------------------------------------------------------

output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint URL for the Kubernetes API server."
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "The ID of the VPC created for the EKS cluster."
  value       = module.vpc.vpc_id
}

output "kubeconfig_command" {
  description = "Command to configure kubectl to connect to the cluster."
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

# ----------------------------------------------------------------------
# EKS IAM Role Outputs
# ----------------------------------------------------------------------

output "eks_cluster_iam_role_name" {
  description = "Name of the IAM role associated with the EKS cluster."
  value       = module.eks.iam_role_name  # References "EKS-Cluster" from main.tf
}

output "eks_cluster_iam_role_arn" {
  description = "ARN of the IAM role associated with the EKS cluster."
  value       = module.eks.iam_role_arn
}
