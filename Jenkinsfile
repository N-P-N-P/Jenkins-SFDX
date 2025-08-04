pipeline {
    agent any

    environment {
        SF_ORG_INSTANCE_URL = 'https://login.salesforce.com'
        PATH = "${WORKSPACE}/sfdx-cli/bin:$PATH"
    }

    stages {
        stage('Checkout Source') {
            steps {
                git url: 'https://github.com/N-P-N-P/Jenkins-SFDX.git', branch: 'main'
            }
        }

        stage('Install Salesforce CLI & Git Delta') {
            steps {
                sh '''
                    echo "Installing legacy Salesforce CLI..."
                    curl -sL https://developer.salesforce.com/media/salesforce-cli/sfdx/channels/stable/sfdx-linux-x64.tar.gz -o sfdx.tar.gz
                    mkdir -p sfdx-cli
                    tar -xzf sfdx.tar.gz -C sfdx-cli --strip-components 1
                    export PATH=${WORKSPACE}/sfdx-cli/bin:$PATH
                    sfdx --version

                    echo "Installing sfdx-git-delta..."
                    npm install -g sfdx-git-delta
                '''
            }
        }

        stage('Authenticate with Salesforce') {
            steps {
                withCredentials([
                    file(credentialsId: 'salesforce-jwt-key', variable: 'SFDX_JWT_KEY'),
                    string(credentialsId: 'salesforce-client-id', variable: 'SFDX_CLIENT_ID'),
                    string(credentialsId: 'your-salesforce-username', variable: 'SFDX_USERNAME')
                ]) {
                    sh '''
                        echo "Authenticating with Salesforce..."
                        export PATH=${WORKSPACE}/sfdx-cli/bin:$PATH
                        sfdx auth:jwt:grant --clientid $SFDX_CLIENT_ID --jwtkeyfile "$SFDX_JWT_KEY" --username $SFDX_USERNAME --instanceurl $SF_ORG_INSTANCE_URL
                        sfdx config:set target-org=$SFDX_USERNAME
                    '''
                }
            }
        }

        stage('Generate Delta') {
            steps {
                sh '''
                    echo "Generating metadata diff using sfdx-git-delta..."
                    git fetch origin main
                    sfdx sgd:source:delta --from "HEAD~1" --to "HEAD" --output changed
                '''
            }
        }

        stage('Deploy Incremental Changes') {
            steps {
                withCredentials([string(credentialsId: 'your-salesforce-username', variable: 'SFDX_USERNAME')]) {
                    sh '''
                        export PATH=${WORKSPACE}/sfdx-cli/bin:$PATH
                        if [ -d "changed/force-app" ]; then
                            echo "Deploying changed metadata..."
                            sfdx force:source:deploy -p changed/force-app --target-org $SFDX_USERNAME --testlevel RunLocalTests
                        else
                            echo "No changes to deploy."
                        fi
                    '''
                }
            }
        }

        stage('Run Apex Tests (if needed)') {
            when {
                expression { fileExists('changed/force-app') }
            }
            steps {
                withCredentials([string(credentialsId: 'your-salesforce-username', variable: 'SFDX_USERNAME')]) {
                    sh '''
                        echo "Running Apex tests..."
                        export PATH=${WORKSPACE}/sfdx-cli/bin:$PATH
                        sfdx apex run test --result-format junit --output-dir test-results --wait 10 --target-org $SFDX_USERNAME
                    '''
                }
            }
            post {
                always {
                    junit 'test-results/test-result-*.xml'
                }
            }
        }

        stage('Post-Deployment Org Info') {
            steps {
                withCredentials([string(credentialsId: 'your-salesforce-username', variable: 'SFDX_USERNAME')]) {
                    sh '''
                        export PATH=${WORKSPACE}/sfdx-cli/bin:$PATH
                        sfdx org display --target-org $SFDX_USERNAME
                    '''
                }
            }
        }
    }

    post {
        success {
            echo ' Incremental deployment completed successfully!'
        }
        failure {
            echo ' Deployment failed. Check logs and test reports for details.'
        }
    }
}
