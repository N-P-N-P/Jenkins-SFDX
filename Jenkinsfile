pipeline {
    agent any

    environment {
        SF_ORG_INSTANCE_URL = 'https://login.salesforce.com'
        SF_CLI_PATH = "${WORKSPACE}/sf/bin"
        PATH = "${PATH}:${SF_CLI_PATH}"
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
                            echo "Installing Salesforce CLI (sf)..."
                            curl -L https://developer.salesforce.com/media/salesforce-cli/sf/channels/stable/sf-linux-x64.tar.xz -o sf.tar.xz
                            tar -xvf sf.tar.xz

                            if [ -f "./sf/bin/sf" ]; then
                                chmod +x ./sf/bin/sf
                                echo "Salesforce CLI installed."
                            else
                                echo "Error: sf binary not found."
                                exit 1
                            fi
                        else
                            echo "Salesforce CLI already installed."
                        fi

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
                            echo "Authenticating with Salesforce..."
                            export PATH=$PATH:"${WORKSPACE}/sf/bin"

                            sf auth jwt grant --client-id $SFDX_CLIENT_ID --jwt-key-file "$SFDX_JWT_KEY" --username $SFDX_USERNAME --instance-url $SF_ORG_INSTANCE_URL

                            echo "Setting default org..."
                            sf config set target-org $SFDX_USERNAME
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
                        sf apex run test --result-format junit --output-dir test-results --wait 10 --target-org $SFDX_USERNAME
                    '''
                    junit 'test-results/test-result-*.xml'
                }
            }
        }

        stage('Deploy to Salesforce') {
            steps {
                script {
                    sh '''
                        echo "Check-only deployment..."
                        export PATH=$PATH:"${WORKSPACE}/sf/bin"
                        sf deploy metadata --metadata-dir force-app --dry-run --test-level RunLocalTests --target-org $SFDX_USERNAME

                        echo "Actual deployment..."
                        sf deploy metadata --metadata-dir force-app --test-level RunLocalTests --target-org $SFDX_USERNAME
                    '''
                }
            }
        }

        stage('Post-Deployment') {
            steps {
                script {
                    sh '''
                        echo "Displaying org info..."
                        export PATH=$PATH:"${WORKSPACE}/sf/bin"
                        sf org display --target-org $SFDX_USERNAME
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