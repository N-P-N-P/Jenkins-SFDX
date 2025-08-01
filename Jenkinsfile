pipeline {
    agent any

    environment {
        SF_ORG_INSTANCE_URL = 'https://login.salesforce.com'
        SFDX_CLI_PATH = "${WORKSPACE}/sfdx-cli/bin"
        PATH = "${PATH}:${SFDX_CLI_PATH}"
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/N-P-N-P/Jenkins-SFDX.git', branch: 'main'
            }
        }

        stage('Install Legacy sfdx CLI') {
            steps {
                script {
                    sh '''
                        echo "Installing legacy sfdx CLI (.tar.gz)..."
                        curl -sL https://developer.salesforce.com/media/salesforce-cli/sfdx/channels/stable/sfdx-linux-x64.tar.gz -o sfdx.tar.gz
                        mkdir -p sfdx-cli
                        tar -xzf sfdx.tar.gz -C sfdx-cli --strip-components 1

                        # Force the use of legacy sfdx CLI by updating the PATH
                        export PATH=${WORKSPACE}/sfdx-cli/bin:$PATH

                        # Verify sfdx version
                        sfdx --version
                    '''
                }
            }
        }

        stage('Install sfdx-git-delta Plugin') {
            steps {
                script {
                    sh '''
                        echo "Installing sfdx-git-delta plugin for sfdx CLI..."
                        sfdx plugins:install sfdx-git-delta --force
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
                            sfdx auth jwt grant --client-id $SFDX_CLIENT_ID --jwt-key-file "$SFDX_JWT_KEY" --username $SFDX_USERNAME --instance-url $SF_ORG_INSTANCE_URL
                            sfdx config set target-org $SFDX_USERNAME
                        '''
                    }
                }
            }
        }

        stage('Generate Delta') {
            steps {
                script {
                    sh '''
                        echo "Generating delta from origin/main to HEAD..."
                        git fetch origin main
                        git diff --name-only origin/main HEAD > changed_files.txt
                        cat changed_files.txt

                        sfdx sgd:source:delta --to HEAD --from origin/main --output delta --generate-delta
                    '''
                }
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
                            sfdx apex run test --result-format junit --output-dir test-results --wait 10 --target-org $SFDX_USERNAME
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
                            if [ -d "delta/package" ]; then
                                echo "Deploying delta changes..."
                                sfdx force:source:deploy -p delta/package --testlevel RunLocalTests --target-org $SFDX_USERNAME
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
                            sfdx org display --target-org $SFDX_USERNAME
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
            echo ' Deployment failed. See logs above for troubleshooting.'
        }
    }
}
