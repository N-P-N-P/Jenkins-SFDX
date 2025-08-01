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

                            # List the files after extraction to understand the directory structure
                            echo "Listing extracted files:"
                            ls -alh

                            # Check if the sf binary is available in the extracted directory
                            echo "Checking for sf binary..."
                            find . -name 'sf'

                            # Now, adjust the path to where the binary is located
                            # The 'sf' binary was found in ./sf/bin/sf, so execute it from there
                            if [ -f "./sf/bin/sf" ]; then
                                echo "Salesforce CLI (sf) binary found at ./sf/bin/sf."
                                chmod +x ./sf/bin/sf
                                export PATH=$PATH:$(pwd)/sf/bin  # Add sf to PATH
                                ./sf/bin/sf --version
                            else
                                echo "Error: Salesforce CLI (sf) binary not found."
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
                        // Securely pass the JWT key file and client ID into the 'sh' step
                        sh """
                            # Authenticate using Salesforce CLI
                            sf force:auth:jwt:grant --clientid ${SFDX_CLIENT_ID} --jwtkeyfile ${SFDX_JWT_KEY} --username ${SFDX_USERNAME} --instanceurl ${SFDX_INSTANCE_URL}
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