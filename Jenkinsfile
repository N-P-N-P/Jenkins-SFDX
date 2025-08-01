pipeline {
    agent any
    
    environment {
        SFDX_INSTANCE_URL = 'https://login.salesforce.com'  // Salesforce instance URL (or test.salesforce.com)
    }
    
    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/N-P-N-P/Jenkins-SFDX.git', branch: 'main'
            }
        }

        stage('Install Salesforce CLI') {
            steps {
                script {
                    // Check if Salesforce CLI (sf) is already installed
                    sh '''
                        if ! command -v sf &> /dev/null
                        then
                            echo "Salesforce CLI not found, installing..."
                            # Download and install Salesforce CLI (sf)
                            curl -L https://developer.salesforce.com/media/salesforce-cli/sf/channels/stable/sf-linux-x64.tar.xz -o sf.tar.xz
                            
                            # Extract the downloaded tar.xz file
                            tar -xvf sf.tar.xz

                            # List files to identify the extracted directory
                            echo "Listing extracted files:"
                            ls -alh

                            # Try to find the directory and cd into it
                            # You should adjust this if the extracted files are in a different folder
                            cd sf-linux-x64 || exit 1  # Modify this line based on the output of ls command

                            # Make sure the install.sh script is executable
                            chmod +x install.sh

                            # Install Salesforce CLI (sf) locally in the Jenkins workspace
                            ./install.sh --no-sudo

                            # Verify installation
                            if command -v sf &> /dev/null; then
                                echo "Salesforce CLI installed successfully"
                            else
                                echo "Salesforce CLI installation failed"
                                exit 1
                            fi
                        else
                            echo "Salesforce CLI is already installed"
                        fi
                    '''
                }
            }
        }

        stage('Authenticate with Salesforce') {
            steps {
                script {
                    withCredentials([
                        file(credentialsId: 'salesforce-jwt-key', variable: 'SFDX_JWT_KEY'),  // Secure JWT key file
                        string(credentialsId: 'salesforce-client-id', variable: 'SFDX_CLIENT_ID'), // Client ID
                        string(credentialsId: 'your-salesforce-username', variable: 'SFDX_USERNAME') // Salesforce Username
                    ]) {
                        sh """
                            sf force:auth:jwt:grant \
                                --clientid ${SFDX_CLIENT_ID} \
                                --jwtkeyfile ${SFDX_JWT_KEY} \
                                --username ${SFDX_USERNAME} \
                                --instanceurl ${SFDX_INSTANCE_URL}
                        """
                    }
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    sh 'sf plugins:install @salesforce/lwc-dev-server'
                    sh 'npm install'   // Assuming npm dependencies are required for your project
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                script {
                    sh 'sf force:apex:test:run --resultformat human --wait 10'
                }
            }
        }
        
        stage('Deploy to Salesforce') {
            steps {
                script {
                    // Use Delta Deployment for faster deployments (only deploy changed files)
                    sh 'sf force:source:deploy -p force-app --checkonly --testlevel RunLocalTests'   // Optional: dry-run deployment
                    
                    // Actual deployment
                    sh 'sf force:source:deploy -p force-app --deploydir deploy --testlevel RunLocalTests'
                }
            }
        }
        
        stage('Post-Deployment') {
            steps {
                script {
                    sh 'sf force:org:display'  // Display org details to verify deployment
                }
            }
        }
    }
    
    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed.'
        }
    }
}