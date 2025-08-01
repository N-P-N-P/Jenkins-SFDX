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
                            echo "Salesforce CLI not found. Installing..."

                            curl -L https://developer.salesforce.com/media/salesforce-cli/sf/channels/stable/sf-linux-x64.tar.xz -o sf.tar.xz
                            tar -xvf sf.tar.xz

                            if [ -f "./sf/bin/sf" ]; then
                                chmod +x ./sf/bin/sf
                                echo "Salesforce CLI installed."
                            else
                                echo "Error: sf binary not found after extraction."
                                exit 1
                            fi
                        else
                            echo "Salesforce CLI is already installed."
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
                            echo "Authenticating with Salesforce using JWT..."
                            export PATH=$PATH:"${WORKSPACE}/sf/bin"

                            sf force:auth:jwt:grant --clientid $SFDX_CLIENT_ID --jwtkeyfile "$SFDX_JWT_KEY" --username $SFDX_USERNAME --instanceurl $SF_ORG_INSTANCE_URL

                            echo "Setting default org..."
                            sf config set target-org=$SFDX_USERNAME
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
                        echo "Check-only deployment..."
                        export PATH=$PATH:"${WORKSPACE}/sf/bin"
                        sf force:source:deploy -p force-app --checkonly --testlevel RunLocalTests

                        echo "Actual deployment..."
                        sf force:source:deploy -p force-app --testlevel RunLocalTests
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
