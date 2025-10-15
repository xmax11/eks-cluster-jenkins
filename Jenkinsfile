// This Jenkinsfile manages the lifecycle of an EKS cluster using Terraform,
// including a secure setup, manual approval, and a timed auto-destroy feature.
pipeline {
    agent any

    // Define environment variables
    environment {
        // --- User-defined variables ---
        AWS_CREDENTIALS_ID = 'aws-jenkins-creds-id' // <<<<< IMPORTANT: REPLACE WITH YOUR AWS CREDENTIAL ID
        TF_VAR_aws_region  = 'us-east-1'            // AWS Region for deployment
        TF_DIR             = 'eks-cluster'          // Directory containing Terraform files
        TF_VAR_cluster_name = 'your-cluster-name'   // <<<<< IMPORTANT: REPLACE WITH YOUR CLUSTER NAME
        AWS_ACCOUNT_ID     = '123456789012'         // Replace with your AWS Account ID
        
        // --- Pipeline control variables ---
        DESTROY_TIMEOUT_SECONDS = 1800 // 30 minutes (30 * 60 = 1800)
    }

    // Wrap the entire pipeline in a credentials block for AWS authentication
    // This assumes you have configured an "AWS Credentials" type in Jenkins.
    stages {
        stage('Secure AWS Setup') {
            steps {
                // Use the configured AWS credentials for all subsequent AWS CLI and Terraform commands.
                // The environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are injected.
                withCredentials([aws(credentialsId: env.AWS_CREDENTIALS_ID, variablePrefix: 'AWS')]) {
                    // This is a placeholder stage. Actual work happens in later stages
                    echo "AWS Credentials are now available in environment variables."
                }
            }
        }
        
        stage('Checkout Code') {
            steps {
                // Retrieves the source code from the Git repository
                checkout scm
            }
        }

        // --- Terraform Stages (Apply) ---

        stage('Terraform Init') {
            steps {
                dir(env.TF_DIR) {
                    sh 'terraform init -upgrade -lock=true'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir(env.TF_DIR) {
                    // Create a plan file to review changes before applying
                    sh 'terraform plan -input=false -out=tfplan'
                }
            }
        }

        stage('Manual Approval for Apply') {
            steps {
                // Pause the pipeline for a manual gate to review the plan output
                input(message: 'Approve or Reject the Terraform plan to apply EKS cluster?', ok: 'Proceed to Apply')
            }
        }

        stage('Terraform Apply') {
            steps {
                dir(env.TF_DIR) {
                    // Apply the cluster changes using the generated plan file
                    sh 'terraform apply -input=false tfplan'
                }
            }
        }

        stage('Configure Kubeconfig') {
            steps {
                // This step must run inside the credentials block to use the injected AWS keys
                withCredentials([aws(credentialsId: env.AWS_CREDENTIALS_ID, variablePrefix: 'AWS')]) {
                    script {
                        // Use AWS CLI to update the Jenkins agent's kubeconfig file
                        sh """
                        # Configure AWS CLI using injected credentials
                        export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY

                        echo "Updating kubeconfig for cluster: ${env.TF_VAR_cluster_name}"
                        aws eks --region ${env.TF_VAR_aws_region} update-kubeconfig --name ${env.TF_VAR_cluster_name} --kubeconfig \$PWD/kubeconfig
                        
                        echo "Verifying cluster nodes..."
                        kubectl --kubeconfig \$PWD/kubeconfig get nodes
                        """
                    }
                }
            }
        }

        // --- Timed Destroy Stages ---

        stage('Wait for Auto-Destroy Timer') {
            steps {
                script {
                    echo "Cluster deployed successfully. Entering ${env.DESTROY_TIMEOUT_SECONDS} second (30 minute) destroy delay."
                    // Sleep for 30 minutes before proceeding to the destroy stage
                    sleep(time: env.DESTROY_TIMEOUT_SECONDS as int, unit: 'SECONDS')
                }
            }
        }

        stage('Manual Approval for Destroy') {
            steps {
                // Optional: A final check before tearing down resources
                input(message: 'Automatic destroy timer has expired. Approve or Reject the Terraform destroy?', ok: 'Proceed to Destroy')
            }
        }

        stage('Terraform Destroy') {
            steps {
                dir(env.TF_DIR) {
                    // Destroy the infrastructure
                    echo "Starting Terraform destroy..."
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
    }
}
