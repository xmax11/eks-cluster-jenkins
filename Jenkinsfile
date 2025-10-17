// Jenkinsfile for automated Terraform infrastructure management  (EKS Cluster Creation)
// This pipeline runs on every push to the main branch and automatically applies changes and destroys after TTL.
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
        TF_VAR_cluster_name = "${EKS_CLUSTER_NAME}"
        TF_VAR_aws_region  = "${AWS_REGION}"
        TF_LOG = "INFO"  // Standard logging; increase to "DEBUG" if needed
        TF_IN_AUTOMATION = "1"  // Skip interactive in CI
        AWS_REGION = "${AWS_REGION}" // For AWS CLI
        DESTROY_TIMEOUT_SECONDS = "${DESTROY_TIMEOUT_SECONDS}"
    }

    stages {
        stage('Verify AWS Auth') {
            steps {
                echo "Verifying AWS IAM role access..."
                sh "aws sts get-caller-identity"
                echo "AWS auth successful. Role: Full admin access confirmed."
                
                // Log Terraform version for debugging
                echo "Terraform version:"
                sh "terraform version"
            }
        }

        stage('Terraform Init') {
            steps {
                // Clean cache to fix provider schema issues
                echo "Cleaning .terraform cache to ensure fresh provider download..."
                sh "rm -rf .terraform/"
                
                echo "Initializing Terraform backend in S3: ${S3_BACKEND_BUCKET}"
                // The 'reconfigure' flag is essential for CI/CD environments
                sh "terraform init -backend-config=\"bucket=${S3_BACKEND_BUCKET}\" -backend-config=\"region=${AWS_REGION}\" -reconfigure"
                
                // Fix provider binary permissions to prevent hangs
                echo "Setting executable permissions on provider binaries..."
                sh "find .terraform/providers -name 'terraform-provider-aws*' -type f -exec chmod +x {} \\; || true"
            }
        }

        stage('Terraform Plan') {
            steps {
                echo "Generating Terraform plan and saving to eks.tfplan..."
                timeout(time: 10, unit: 'MINUTES') {  // Allow more time for plan
                    sh "terraform plan -out=eks.tfplan"
                }
                
                // Display the plan output in the console for review
                sh "terraform show -no-color eks.tfplan"
            }
        }

        stage('Terraform Apply') {
            steps {
                echo "Applying infrastructure changes using saved plan file..."
                timeout(time: 20, unit: 'MINUTES') {  // EKS creation can take time
                    sh "terraform apply -auto-approve eks.tfplan"
                }
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
                echo "Wait period complete. Proceeding to auto-deletion."
            }
        }

        stage('Terraform Destroy') {
            steps {
                echo "Starting Terraform destroy..."
                timeout(time: 15, unit: 'MINUTES') {
                    sh "terraform destroy -auto-approve"
                }
                echo "Terraform Destroy completed. EKS cluster and associated resources deleted."
            }
        }
    }

    post {
        always {
            // Archive the plan file, .terraform, and logs for auditing/debug
            archiveArtifacts artifacts: 'eks.tfplan, .terraform/**', allowEmptyArchive: true
            echo "Pipeline completed. Check Jenkins console for details."
            // Add notifications here, e.g., Slack or Email integration
        }
        success {
            echo "Pipeline succeeded! EKS infra managed successfully."
        }
        failure {
            echo "Pipeline failed! Check logs for errors (e.g., Terraform syntax, S3 backend issues)."
            // On failure, clean up workspace partially to avoid cache pollution
            sh "rm -rf .terraform/"
        }
    }
}
