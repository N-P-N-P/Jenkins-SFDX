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
                    // Install Salesforce CLI if it's not already installed
                    sh '''
                        if ! command -v sfdx &> /dev/null
                        then
                            echo "Salesforce CLI not found, installing..."
                            # Download and install Salesforce CLI (for Linux/Unix-based systems)
                            wget https://developer.salesforce.com/media/salesforce-cli/sfdx-linux-x64.tar.xz
                            tar -xvf sfdx-linux-x64.tar.xz
                            ./sfdx/install
                            # Add sfdx to the PATH
                            export PATH=$PATH:$(pwd)/sfdx/bin
                            echo "Salesforce CLI installed successfully"
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
                            sfdx force:auth:jwt:grant \
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
                    // Make sure sfdx plugins are installed, if needed
                    sh 'sfdx plugins:install @salesforce/lwc-dev-server'
                    sh 'npm install'   // Assuming npm dependencies are required for your project
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                script {
                    sh 'sfdx force:apex:test:run --resultformat human --wait 10'
                }
            }
        }
        
        stage('Deploy to Salesforce') {
            steps {
                script {
                    // Use Delta Deployment for faster deployments (only deploy changed files)
                    sh 'sfdx force:source:deploy -p force-app --checkonly --testlevel RunLocalTests'   // Optional: dry-run deployment
                    
                    // Actual deployment
                    sh 'sfdx force:source:deploy -p force-app --deploydir deploy --testlevel RunLocalTests'
                }
            }
        }
        
        stage('Post-Deployment') {
            steps {
                script {
                    sh 'sfdx force:org:display'  // Display org details to verify deployment
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