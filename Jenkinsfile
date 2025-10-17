// Jenkinsfile for automated Terraform infrastructure management (EKS Cluster Creation)
// This pipeline runs on every push to the main branch but requires manual approval for 'apply' and 'destroy'.
// Uses IAM role on Jenkins EC2 for AWS auth (no credentials stored).

// --- Configuration Variables ---
def AWS_REGION = "us-east-1"                    // Your AWS region (matches variables.tf)
def EKS_CLUSTER_NAME = "jenkins-managed-eks"    // Matches default in variables.tf
def S3_BACKEND_BUCKET = "my-terraform-eks-state-bucket-malghani" // Matches backend.tf bucket
def DESTROY_DELAY_MINUTES = 30                  // Time-to-live before deletion attempt

// --- Calculated Variables ---
def DESTROY_TIMEOUT_SECONDS = DESTROY_DELAY_MINUTES * 60

// -------------------------------

pipeline {
    agent any // Use 'any' for flexibility; ensure agent has Terraform/AWS CLI installed
    
    environment {
        // Set environment variables for Terraform and AWS CLI access
        // AWS creds auto-provided by IAM role on EC2 instance
        TF_VAR_cluster_name = EKS_CLUSTER_NAME
        TF_VAR_aws_region  = AWS_REGION
        TF_LOG_LEVEL = "INFO"
        AWS_REGION = AWS_REGION // For AWS CLI
        DESTROY_TIMEOUT_SECONDS = DESTROY_TIMEOUT_SECONDS
    }

    stages {
        stage('Verify AWS Auth') {
            steps {
                echo "Verifying AWS IAM role access..."
                sh "aws sts get-caller-identity"
                echo "AWS auth successful. Role: Full admin access confirmed."
            }
        }

        stage('Terraform Init') {
            steps {
                echo "Initializing Terraform backend in S3: ${S3_BACKEND_BUCKET}"
                // The 'reconfigure' flag is essential for CI/CD environments
                sh "terraform init -backend-config=\"bucket=${S3_BACKEND_BUCKET}\" -backend-config=\"region=${AWS_REGION}\" -reconfigure"
            }
        }

        stage('Terraform Validate and Plan') {
            steps {
                echo "Validating Terraform configuration..."
                sh "terraform validate"

                echo "Generating Terraform plan and saving to eks.tfplan..."
                // Create a plan file to review and use later in the apply stage
                sh "terraform plan -out=eks.tfplan"
                
                // Display the plan output in the console for review
                sh "terraform show -no-color eks.tfplan"
            }
        }

        stage('Manual Approval for Apply') {
            steps {
                // This halts the pipeline for human review
                input(
                    id: 'ProceedWithTerraformApply',
                    message: "Review the 'Terraform Plan' output. Do you approve applying these changes to the AWS infrastructure?",
                    ok: 'Proceed with Apply'
                )
            }
        }

        stage('Terraform Apply') {
            steps {
                echo "Applying infrastructure changes using saved plan file..."
                sh "terraform apply -auto-approve eks.tfplan"
                echo "Terraform Apply completed. EKS cluster '${EKS_CLUSTER_NAME}' created in region '${AWS_REGION}'."
                
                // Output EKS Cluster IAM Role details
                script {
                    def clusterRoleName = sh(script: 'terraform output -raw eks_cluster_iam_role_name', returnStdout: true).trim()
                    def clusterRoleArn = sh(script: 'terraform output -raw eks_cluster_iam_role_arn', returnStdout: true).trim()
                    echo "EKS Cluster IAM Role Name: ${clusterRoleName}"
                    echo "EKS Cluster IAM Role ARN: ${clusterRoleArn}"
                }
                
                // Optional: Output kubeconfig command for quick access
                script {
                    def kubeconfig = sh(script: 'terraform output -raw kubeconfig_command', returnStdout: true).trim()
                    echo "Run this to connect: ${kubeconfig}"
                }
            }
        }

        stage('Wait for Deletion TTL') {
            steps {
                echo "Wait period started. Infrastructure will be eligible for deletion in ${DESTROY_DELAY_MINUTES} minutes."
                sleep(time: DESTROY_TIMEOUT_SECONDS as int, unit: 'SECONDS')
                echo "Wait period complete. Proceeding to deletion approval."
            }
        }
        
        stage('Manual Approval for Deletion') {
            steps {
                input(
                    id: 'ProceedWithTerraformDestroy',
                    message: "The time-to-live (${DESTROY_DELAY_MINUTES} minutes) has expired. Do you approve DESTROYING the AWS EKS infrastructure?",
                    ok: 'Proceed with Destroy'
                )
            }
        }

        stage('Terraform Destroy') {
            steps {
                echo "Starting Terraform destroy..."
                sh "terraform destroy -auto-approve"
                echo "Terraform Destroy completed. EKS cluster and associated resources deleted."
            }
        }
    }

    post {
        always {
            // Archive the plan file for auditing
            archiveArtifacts artifacts: 'eks.tfplan', allowEmptyArchive: true
            echo "Pipeline completed. Check Jenkins console for details."
            // Add notifications here, e.g., Slack or Email integration
        }
        success {
            echo "Pipeline succeeded! EKS infra managed successfully."
        }
        failure {
            echo "Pipeline failed! Check logs for errors (e.g., Terraform syntax, S3 backend issues)."
        }
    }
}
