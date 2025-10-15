# ----------------------------------------------------------------------
# AWS Provider Variables
# ----------------------------------------------------------------------
variable "aws_region" {
  description = "The AWS region to deploy the EKS cluster into."
  type        = string
  default     = "us-east-1"
}

# ----------------------------------------------------------------------
# EKS Cluster Variables
# ----------------------------------------------------------------------
variable "cluster_name" {
  description = "Name for the EKS cluster and related resources."
  type        = string
  default     = "jenkins-managed-eks"
}

variable "kubernetes_version" {
  description = "The version of Kubernetes to use for the EKS cluster."
  type        = string
  default     = "1.29"
}

# ----------------------------------------------------------------------
# Node Group Variables
# ----------------------------------------------------------------------
variable "instance_type" {
  description = "The EC2 instance type for the EKS worker nodes."
  type        = string
  default     = "t3.medium"
}

variable "min_size" {
  description = "Minimum size of the EKS node group."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum size of the EKS node group."
  type        = number
  default     = 5
}