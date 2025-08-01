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
                            # Download Salesforce CLI (sf)
                            curl -L https://developer.salesforce.com/media/salesforce-cli/sf/channels/stable/sf-linux-x64.tar.xz -o sf.tar.xz
                            
                            # Extract the downloaded tar.xz file
                            tar -xvf sf.tar.xz

                            # List files in the current directory after extraction
                            echo "Listing extracted files:"
                            ls -alh

                            # List files inside the extracted folder (if any)
                            find . -type f

                            # Check if 'install.sh' exists and make it executable
                            if [ -f "install.sh" ]; then
                                chmod +x install.sh
                                ./install.sh --no-sudo
                            else
                                echo "Error: install.sh script not found."
                                exit 1
                            fi

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