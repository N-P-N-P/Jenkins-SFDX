pipeline {
    agent any

    environment {
        SF_ORG_INSTANCE_URL = 'https://login.salesforce.com'
        SFDX_CLI_DIR = "${WORKSPACE}/sfdx-cli"
        PATH = "${WORKSPACE}/sfdx-cli/bin:$PATH"
    }

    stages {
        stage('Checkout Source') {
            steps {
                git url: 'https://github.com/N-P-N-P/Jenkins-SFDX.git', branch: 'main'
            }
        }

        stage('Create .forceignore') {
            steps {
                script {
                    writeFile file: '.forceignore', text: '''
force-app/main/default/extlClntAppPolicies/Devops_JWT_plcy.ecaPlcy-meta.xml
                    '''.stripIndent()
                }
            }
        }

        stage('Install legacy SFDX CLI') {
            steps {
                sh '''
                    echo "Installing legacy sfdx CLI (.tar.gz)..."
                    curl -sL https://developer.salesforce.com/media/salesforce-cli/sfdx/channels/stable/sfdx-linux-x64.tar.gz -o sfdx.tar.gz
                    mkdir -p sfdx-cli
                    tar -xzf sfdx.tar.gz -C sfdx-cli --strip-components 1
                    export PATH=${WORKSPACE}/sfdx-cli/bin:$PATH
                    sfdx --version
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

        stage('Run Apex Tests') {
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

        stage('Deploy Full Source (force-app)') {
            steps {
                withCredentials([string(credentialsId: 'your-salesforce-username', variable: 'SFDX_USERNAME')]) {
                    sh '''
                        echo "Deploying full source from force-app directory..."
                        export PATH=${WORKSPACE}/sfdx-cli/bin:$PATH
                        sfdx force:source:deploy -p force-app --target-org $SFDX_USERNAME --testlevel RunLocalTests
                    '''
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
            echo ' Deployment completed successfully!'
        }
        failure {
            echo ' Deployment failed. Check the logs for more information.'
        }
    }
}
