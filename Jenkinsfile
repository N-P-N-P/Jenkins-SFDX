pipeline {
    agent any

    environment {
        SFDX_INSTANCE_URL = 'https://login.salesforce.com'  // Salesforce instance URL
        SF_CLI_PATH = "/var/lib/jenkins/workspace/Jenkins SFDX/sf/bin"  // Path to Salesforce CLI binary
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
                    // Check if sf is already installed
                    sh '''
                        if ! command -v sf &> /dev/null
                        then
                            echo "Salesforce CLI (sf) not found, installing..."
                            # Download Salesforce CLI
                            curl -L https://developer.salesforce.com/media/salesforce-cli/sf/channels/stable/sf-linux-x64.tar.xz -o sf.tar.xz
                            
                            # Extract the downloaded tar.xz file
                            tar -xvf sf.tar.xz

                            # List the extracted files for debugging
                            echo "Extracted files:"
                            ls -l

                            # Check if the 'sf' binary exists in the extracted folder
                            if [ -f "./sf/bin/sf" ]; then
                                echo "Salesforce CLI (sf) binary found."
                                chmod +x ./sf/bin/sf
                                
                                # Add sf binary to PATH explicitly for this stage
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
                    // After adding to PATH, check if `sf` works by checking its version
                    sh '''
                        echo "Checking Salesforce CLI version..."
                        export PATH=$PATH:$(pwd)/sf/bin  # Explicitly set PATH again
                        sf --version
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
                        // Ensure that the file path is correct by checking the location of the JWT key
                        echo "JWT key file: $SFDX_JWT_KEY"
                        sh '''
                            echo "Authenticating with Salesforce using JWT..."
                            export PATH=$PATH:$(pwd)/sf/bin  # Ensure PATH is correctly set

                            # Use the full file path for JWT key file argument
                            sf force:auth:jwt:grant --clientid $SFDX_CLIENT_ID --jwtkeyfile "$SFDX_JWT_KEY" --username $SFDX_USERNAME --instanceurl $SFDX_INSTANCE_URL
                        '''
                    }
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    sh '''
                        # Ensure sf is in the PATH
                        export PATH=$PATH:${WORKSPACE}/sf/bin

                        echo "Installing LWC Dev Server plugin..."
                        sf plugins:install @salesforce/lwc-dev-server
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    sh '''
                        echo "Running tests..."
                        sf force:apex:test:run --resultformat human --wait 10
                    '''
                }
            }
        }

        stage('Deploy to Salesforce') {
            steps {
                script {
                    // Use Delta Deployment for faster deployments (only deploy changed files)
                    sh '''
                        echo "Deploying source to Salesforce..."
                        sf force:source:deploy -p force-app --checkonly --testlevel RunLocalTests
                    '''
                    
                    // Actual deployment
                    sh '''
                        echo "Deploying source to Salesforce..."
                        sf force:source:deploy -p force-app --deploydir deploy --testlevel RunLocalTests
                    '''
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