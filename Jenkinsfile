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

        stage('Install sfdx-git-delta Plugin') {
            steps {
                sh '''
                    echo "Installing sfdx-git-delta plugin..."
                    export PATH=${WORKSPACE}/sfdx-cli/bin:$PATH
                    echo y | sfdx plugins:install sfdx-git-delta --force
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
                    echo "Generating delta from main branch..."
                    export PATH=${WORKSPACE}/sfdx-cli/bin:$PATH
                    git fetch origin main
                    git diff --name-only origin/main HEAD > changed_files.txt
                    cat changed_files.txt
                    sfdx sgd:source:delta --to HEAD --from origin/main --output delta --generate-delta
                '''
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

        stage('Deploy Delta Changes') {
            steps {
                withCredentials([string(credentialsId: 'your-salesforce-username', variable: 'SFDX_USERNAME')]) {
                    sh '''
                        export PATH=${WORKSPACE}/sfdx-cli/bin:$PATH
                        if [ -d "delta/package" ]; then
                            echo "Deploying delta changes..."
                            sfdx force:source:deploy -p delta/package --target-org $SFDX_USERNAME --testlevel RunLocalTests
                        else
                            echo "No delta/package directory found. Skipping deployment."
                        fi
                    '''
                }
            }
        }

        stage('Org Info') {
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
            echo ' Delta deployment succeeded!'
        }
        failure {
            echo ' Deployment failed. Check logs.'
        }
    }
}
