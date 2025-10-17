// Jenkinsfile for automated Terraform infrastructure management (EKS Cluster Creation)
// This pipeline runs on every push to the main branch but requires manual approval for 'apply' and 'destroy '.

// --- Configuration Variables ---
def AWS_REGION = "us-east-1"                    // Your AWS region (matches variables.tf)
def EKS_CLUSTER_NAME = "jenkins-managed-eks"    // Matches default in variables.tf
def KUBE_CREDENTIALS_ID = "aws-jenkins-creds-id" // <<<<< IMPORTANT: REPLACE WITH YOUR AWS CREDENTIAL ID
def S3_BACKEND_BUCKET = "my-terraform-eks-state-bucket-malghani" // Matches backend.tf bucket
def DESTROY_DELAY_MINUTES = 30                  // Time-to-live before deletion attempt

// --- Calculated Variables ---
def DESTROY_TIMEOUT_SECONDS = DESTROY_DELAY_MINUTES * 60

// -------------------------------

pipeline {
    agent any // Changed from 'label' to 'any' for simple setup, install terraform/aws-cli on the primary agent
    
    environment {
        // Set environment variable for Terraform and AWS CLI access
        // These are passed to Terraform via -var or environment injection
        TF_VAR_cluster_name = EKS_CLUSTER_NAME
        TF_VAR_aws_region  = AWS_REGION
        TF_LOG_LEVEL = "INFO"
        AWS_CREDENTIALS_ID = KUBE_CREDENTIALS_ID
        DESTROY_TIMEOUT_SECONDS = DESTROY_TIMEOUT_SECONDS
    }

    // Wrap the entire pipeline in a credentials block for AWS authentication
    stages {
        stage('Secure AWS Setup') {
            steps {
                // Use the configured AWS credentials for all subsequent AWS CLI and Terraform commands.
                // The environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are injected.
                withCredentials([aws(credentialsId: env.AWS_CREDENTIALS_ID, variablePrefix: 'AWS')]) {
                    echo "AWS Credentials loaded successfully."
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([aws(credentialsId: env.AWS_CREDENTIALS_ID, variablePrefix: 'AWS')]) {
                    echo "Initializing Terraform backend in S3: ${S3_BACKEND_BUCKET}"
                    // The 'reconfigure' flag is essential for CI/CD environments
                    sh "terraform init -backend-config=\"bucket=${S3_BACKEND_BUCKET}\" -backend-config=\"region=${AWS_REGION}\" -reconfigure"
                }
            }
        }

        stage('Terraform Validate and Plan') {
            steps {
                withCredentials([aws(credentialsId: env.AWS_CREDENTIALS_ID, variablePrefix: 'AWS')]) {
                    echo "Validating Terraform configuration..."
                    sh "terraform validate"

                    echo "Generating Terraform plan and saving to eks.tfplan..."
                    // Create a plan file to review and use later in the apply stage
                    sh "terraform plan -out=eks.tfplan"
                    
                    // Display the plan output in the console for review
                    sh "terraform show -no-color eks.tfplan"
                }
            }
        }

        stage('Manual Approval for Apply') {
            steps {
                // IMPORTANT: This stage halts the pipeline and requires a user to click "Proceed" in Jenkins.
                input(
                    id: 'ProceedWithTerraformApply',
                    message: "Review the 'Terraform Plan' output. Do you approve applying these changes to the AWS infrastructure?",
                    ok: 'Proceed with Apply'
                )
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([aws(credentialsId: env.AWS_CREDENTIALS_ID, variablePrefix: 'AWS')]) {
                    echo "Applying infrastructure changes using saved plan file..."
                    // Apply the previously generated and approved plan file
                    sh "terraform apply -auto-approve eks.tfplan"
                    echo "Terraform Apply completed. EKS cluster changes should now be visible in AWS."
                }
            }
        }

        stage('Wait for Deletion TTL') {
            steps {
                echo "Wait period started. Infrastructure will be eligible for deletion in ${DESTROY_DELAY_MINUTES} minutes."
                // Pauses the pipeline for the configured time
                sleep(time: DESTROY_TIMEOUT_SECONDS as int, unit: 'SECONDS')
                echo "Wait period complete. Proceeding to deletion approval."
            }
        }
        
        stage('Manual Approval for Deletion') {
            steps {
                // Another safety gate to prevent accidental deletion if the pipeline ran overnight, etc.
                input(
                    id: 'ProceedWithTerraformDestroy',
                    message: "The time-to-live (${DESTROY_DELAY_MINUTES} minutes) has expired. Do you approve DESTROYING the AWS EKS infrastructure?",
                    ok: 'Proceed with Destroy'
                )
            }
        }

        stage('Terraform Destroy') {
            steps {
                withCredentials([aws(credentialsId: env.AWS_CREDENTIALS_ID, variablePrefix: 'AWS')]) {
                    echo "Starting Terraform destroy..."
                    // Uses -auto-approve because manual approval was provided in the preceding stage.
                    sh "terraform destroy -auto-approve"
                    echo "Terraform Destroy completed. EKS cluster and associated resources have been deleted."
                }
            }
        }
    }
}
