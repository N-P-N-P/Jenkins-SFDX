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
                        if ! command -v sf &> /dev/null; then
                            echo "Installing Salesforce CLI..."
                            curl -L https://developer.salesforce.com/media/salesforce-cli/sf/channels/stable/sf-linux-x64.tar.xz -o sf.tar.xz
                            tar -xvf sf.tar.xz
                            chmod +x ./sf/bin/sf
                            echo "Salesforce CLI installed."
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
                            sf config set target-org $SFDX_USERNAME
                        '''
                    }
                }
            }
        }

        stage('Install Delta Plugin') {
            steps {
                sh '''
                    echo "Installing sfdx-git-delta plugin..."
                    export PATH=$PATH:"${WORKSPACE}/sf/bin"
                    sf plugins install sfdx-git-delta || echo "Plugin already installed"
                '''
            }
        }

        stage('Generate Delta') {
            steps {
                sh '''
                    echo "Generating delta from last commit..."
                    export PATH=$PATH:"${WORKSPACE}/sf/bin"
                    git fetch origin main
                    git diff --name-only origin/main HEAD > changed_files.txt
                    echo "Changed files:"
                    cat changed_files.txt

                    # Generate delta with sgd plugin
                    sf sgd source delta --to HEAD --from origin/main --output delta --generate-delta
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

        stage('Delta Deploy') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'your-salesforce-username', variable: 'SFDX_USERNAME')
                    ]) {
                        sh '''
                            echo "Deploying delta changes..."
                            export PATH=$PATH:"${WORKSPACE}/sf/bin"

                            if [ -d "delta/package" ]; then
                                echo "Delta package directory found. Deploying..."
                                sf deploy metadata --metadata-dir delta/package --test-level RunLocalTests --target-org $SFDX_USERNAME
                            else
                                echo "No delta changes detected. Skipping deployment."
                            fi
                        '''
                    }
                }
            }
        }

        stage('Post-Deployment Org Info') {
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
            echo ' Deployment completed successfully using delta strategy!'
        }
        failure {
            echo ' Deployment failed. Check logs for details.'
        }
    }
}
