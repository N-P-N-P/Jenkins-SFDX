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
                    // Check if Salesforce CLI is already installed
                    sh '''
                        if ! command -v sfdx &> /dev/null
                        then
                            echo "Salesforce CLI not found, installing..."
                            # Try downloading and installing Salesforce CLI from the correct URL
                            curl -L https://developer.salesforce.com/media/salesforce-cli/sfdx-linux-x64.tar.xz -o sfdx.tar.xz
                            
                            # Check if the download was successful and if the file is a valid archive
                            if [ -s sfdx.tar.xz ]; then
                                echo "Salesforce CLI downloaded successfully"
                                tar -xvf sfdx.tar.xz
                                ./sfdx/install
                                export PATH=$PATH:$(pwd)/sfdx/bin
                                echo "Salesforce CLI installed successfully"
                            else
                                echo "Salesforce CLI download failed"
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