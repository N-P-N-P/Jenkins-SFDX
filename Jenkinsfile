pipeline {
    agent any

    environment {
        SF_ORG_INSTANCE_URL = 'https://login.salesforce.com'
        SF_CLI_PATH = "${WORKSPACE}/sf/bin"
        SFDX_CLI_PATH = "${WORKSPACE}/sfdx-cli/bin"
        PATH = "${PATH}:${SF_CLI_PATH}:${SFDX_CLI_PATH}"
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
                        if ! command -v sf &> /dev/null; then
                            echo "Installing Salesforce CLI (sf)..."
                            curl -L https://developer.salesforce.com/media/salesforce-cli/sf/channels/stable/sf-linux-x64.tar.xz -o sf.tar.xz
                            tar -xvf sf.tar.xz
                            chmod +x ./sf/bin/sf
                        fi
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
                            export PATH=$PATH:"${WORKSPACE}/sf/bin"
                            echo "Authenticating..."
                            sf auth jwt grant --client-id $SFDX_CLIENT_ID --jwt-key-file "$SFDX_JWT_KEY" --username $SFDX_USERNAME --instance-url $SF_ORG_INSTANCE_URL
                            sf config set target-org $SFDX_USERNAME
                        '''
                    }
                }
            }
        }

        stage('Install sfdx CLI + Delta Plugin') {
            steps {
                sh '''
                    echo "Installing legacy sfdx CLI..."
                    curl -s https://developer.salesforce.com/media/salesforce-cli/sfdx-linux-x64.tar.xz -o sfdx.tar.xz
                    mkdir -p sfdx-cli
                    tar -xJf sfdx.tar.xz -C sfdx-cli --strip-components 1
                    export PATH=$PATH:"${WORKSPACE}/sfdx-cli/bin"

                    echo "Installing sfdx-git-delta plugin..."
                    sfdx plugins:install sfdx-git-delta
                    sfdx plugins
                '''
            }
        }

        stage('Generate Delta') {
            steps {
                sh '''
                    echo "Generating delta from origin/main to HEAD..."
                    git fetch origin main
                    git diff --name-only origin/main HEAD > changed_files.txt
                    cat changed_files.txt

                    export PATH=$PATH:"${WORKSPACE}/sfdx-cli/bin"
                    sfdx sgd:source:delta --to HEAD --from origin/main --output delta --generate-delta
                '''
            }
        }

        stage('Run Apex Tests') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'your-salesforce-username', variable: 'SFDX_USERNAME')
                    ]) {
                        sh '''
                            echo "Running Apex tests..."
                            export PATH=$PATH:"${WORKSPACE}/sf/bin"
                            sf apex run test --result-format junit --output-dir test-results --wait 10 --target-org $SFDX_USERNAME
                        '''
                        junit 'test-results/test-result-*.xml'
                    }
                }
            }
        }

        stage('Deploy Delta Changes') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'your-salesforce-username', variable: 'SFDX_USERNAME')
                    ]) {
                        sh '''
                            export PATH=$PATH:"${WORKSPACE}/sf/bin"

                            if [ -d "delta/package" ]; then
                                echo "Deploying delta changes..."
                                sf deploy metadata --metadata-dir delta/package --test-level RunLocalTests --target-org $SFDX_USERNAME
                            else
                                echo "No delta/package directory found. Skipping deployment."
                            fi
                        '''
                    }
                }
            }
        }

        stage('Post-Deployment Info') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'your-salesforce-username', variable: 'SFDX_USERNAME')
                    ]) {
                        sh '''
                            export PATH=$PATH:"${WORKSPACE}/sf/bin"
                            sf org display --target-org $SFDX_USERNAME
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo ' Delta deployment completed successfully!'
        }
        failure {
            echo ' Deployment failed. Check logs for error details.'
        }
    }
}
