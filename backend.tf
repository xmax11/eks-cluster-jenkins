terraform {
  backend "s3" {
    bucket         = "my-terraform-eks-state-bucket-malghani"
    key            = "eks-cluster/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "my-terraform-locks" # <== Keep this for S3 locking
    encrypt        = true
  }
}