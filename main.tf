# versions.tf (or main.tf)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Require a version compatible with the latest EKS module
      version = "~> 5.0" 
    }
  }
}
# 1. AWS Provider Configuration
provider "aws" {
  region = var.aws_region
}

# 2. VPC Module (Highly Recommended to use a separate module for VPC)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs                  = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# 3. EKS Cluster Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.0.0" # Use a recent stable version

  cluster_name    = var.cluster_name
  cluster_version = "1.29" # Specify your desired Kubernetes version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  # EKS Managed Node Group
  eks_managed_node_groups = {
    general = {
      disk_size      = 50
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 5
      desired_size   = 2
    }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}