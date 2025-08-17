pipeline {
    agent any

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Git Branch to Deploy')
        choice(name: 'SF_ENV', choices: ['dev', 'qa', 'prod'], description: 'Salesforce Environment')
    }

    environment {
        SF_ORG_INSTANCE_URL = 'https://login.salesforce.com'
        PATH = "${WORKSPACE}/sfdx-cli/bin:$PATH"
    }

    stages {
        stage('Checkout Source') {
            steps {
                git url: 'https://github.com/N-P-N-P/Jenkins-SFDX.git', branch: "${params.BRANCH_NAME}"
            }
        }

        stage('Install Salesforce CLI & Git Delta') {
            steps {
                sh '''
                    echo "Installing Salesforce CLI..."
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
                    string(credentialsId: "salesforce-username-${params.SF_ENV}", variable: 'SFDX_USERNAME')
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
                    echo "Generating metadata delta..."
                    git fetch origin ${params.BRANCH_NAME}
                    sfdx sgd:source:delta --from "HEAD~1" --to "HEAD" --output changed
                '''
            }
        }

        stage('Validate Metadata') {
            when {
                expression { fileExists('changed/force-app') }
            }
            steps {
                withCredentials([string(credentialsId: "salesforce-username-${params.SF_ENV}", variable: 'SFDX_USERNAME')]) {
                    sh '''
                        echo "Validating metadata with Apex tests..."
                        export PATH=${WORKSPACE}/sfdx-cli/bin:$PATH
                        sfdx force:source:deploy -p changed/force-app --target-org $SFDX_USERNAME --checkonly --testlevel RunLocalTests --wait 10
                    '''
                }
            }
        }

        stage('Deploy Changes') {
            when {
                expression { fileExists('changed/force-app') }
            }
            steps {
                withCredentials([string(credentialsId: "salesforce-username-${params.SF_ENV}", variable: 'SFDX_USERNAME')]) {
                    sh '''
                        echo "Deploying validated metadata..."
                        export PATH=${WORKSPACE}/sfdx-cli/bin:$PATH
                        sfdx force:source:deploy -p changed/force-app --target-org $SFDX_USERNAME --testlevel NoTestRun --wait 10
                    '''
                }
            }
        }

        stage('Post-Deployment Org Info') {
            steps {
                withCredentials([string(credentialsId: "salesforce-username-${params.SF_ENV}", variable: 'SFDX_USERNAME')]) {
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
            echo ' Deployment failed. Check logs and test results.'
        }
    }
}
