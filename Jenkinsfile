pipeline {
    agent any

    environment {
        // Salesforce CLI Environment Variables
        SFDX_INSTANCE_URL = 'https://login.salesforce.com'
        SF_CLI_PATH = "${WORKSPACE}/sf/bin"
        PATH = "${PATH}:${SF_CLI_PATH}"  // Add sf binary to PATH
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
                    sh '''
                        if ! command -v sf &> /dev/null
                        then
                            echo "Salesforce CLI (sf) not found, installing..."

                            # Download Salesforce CLI
                            curl -L https://developer.salesforce.com/media/salesforce-cli/sf/channels/stable/sf-linux-x64.tar.xz -o sf.tar.xz
                            
                            # Extract the tarball
                            tar -xvf sf.tar.xz

                            # Verify the binary
                            if [ -f "./sf/bin/sf" ]; then
                                echo "Salesforce CLI binary found."
                                chmod +x ./sf/bin/sf
                                echo "Salesforce CLI installed."
                            else
                                echo "Error: sf binary not found after extraction."
                                exit 1
                            fi
                        else
                            echo "Salesforce CLI is already installed."
                        fi

                        # Check CLI version
                        export PATH=$PATH:"${WORKSPACE}/sf/bin"
                        sf --version
                    '''
                }
            }
        }

        stage('Authenticate with Salesforce') {
            steps {
                script {
                    withCredentials([ 
                        file(credentialsId: 'salesforce-jwt-key', variable: 'SFDX_JWT_KEY'),
                        string(credentialsId: 'salesforce-client-id', variable: 'SFDX_CLIENT_ID'),
                        string(credentialsId: 'your-salesforce-username', variable: 'SFDX_USERNAME')
                    ]) {
                        sh '''
                            echo "Authenticating with Salesforce using JWT..."
                            export PATH=$PATH:"${WORKSPACE}/sf/bin"
                            sf force:auth:jwt:grant --clientid $SFDX_CLIENT_ID --jwtkeyfile "$SFDX_JWT_KEY" --username $SFDX_USERNAME --instanceurl $SFDX_INSTANCE_URL
                        '''
                    }
                }
            }
        }

        stage('Run Apex Tests') {
            steps {
                script {
                    sh '''
                        echo "Running Apex tests..."
                        export PATH=$PATH:"${WORKSPACE}/sf/bin"
                        sf force:apex:test:run --resultformat junit --outputdir test-results --wait 10
                    '''
                    junit 'test-results/test-result-*.xml'
                }
            }
        }

        stage('Deploy to Salesforce') {
            steps {
                script {
                    sh '''
                        echo "Deploying metadata (check only)..."
                        export PATH=$PATH:"${WORKSPACE}/sf/bin"
                        sf force:source:deploy -p force-app --checkonly --testlevel RunLocalTests

                        echo "Deploying metadata (actual deployment)..."
                        sf force:source:deploy -p force-app --testlevel RunLocalTests
                    '''
                }
            }
        }

        stage('Post-Deployment') {
            steps {
                script {
                    sh '''
                        echo "Displaying org information..."
                        export PATH=$PATH:"${WORKSPACE}/sf/bin"
                        sf org display
                    '''
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
