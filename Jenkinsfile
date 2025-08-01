pipeline {
    agent any
    
    environment {
        SFDX_INSTANCE_URL = 'https://login.salesforce.com'  // Salesforce instance URL
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/N-P-N-P/Jenkins-SFDX.git', branch: 'main'
            }
        }

        stage('Install Salesforce CLI (sf)') {
            steps {
                script {
                    // Download the Salesforce CLI if it's not installed
                    sh '''
                        if ! command -v sf &> /dev/null
                        then
                            echo "Salesforce CLI (sf) not found, installing..."
                            # Download Salesforce CLI
                            curl -L https://developer.salesforce.com/media/salesforce-cli/sf/channels/stable/sf-linux-x64.tar.xz -o sf.tar.xz
                            
                            # Extract the downloaded tar.xz file
                            tar -xvf sf.tar.xz
                            
                            # Check if the 'sf' binary exists in the extracted folder
                            if [ -f "./sf/bin/sf" ]; then
                                echo "Salesforce CLI (sf) binary found."
                                chmod +x ./sf/bin/sf
                                export PATH=$PATH:$(pwd)/sf/bin
                                echo "Salesforce CLI added to PATH."
                            else
                                echo "Error: Salesforce CLI (sf) binary not found."
                                exit 1
                            fi
                        else
                            echo "Salesforce CLI (sf) is already installed."
                        fi
                    '''
                    // Check if `sf` CLI is installed correctly
                    sh 'sf --version'
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
                        // Use sf CLI to authenticate
                        sh '''
                            echo "Authenticating with Salesforce using JWT..."
                            sf force:auth:jwt:grant --clientid $SFDX_CLIENT_ID --jwtkeyfile $SFDX_JWT_KEY --username $SFDX_USERNAME --instanceurl $SFDX_INSTANCE_URL
                        '''
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