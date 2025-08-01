pipeline {
    agent any

    environment {
        // Salesforce CLI Environment Variables
        SFDX_INSTANCE_URL = 'https://login.salesforce.com'  // Salesforce instance URL
        SF_CLI_PATH = "/var/lib/jenkins/workspace/Jenkins SFDX/sf/bin"  // Path to Salesforce CLI binary
        
        // Spark Home and Delta core JAR location (for Delta processing)
        SPARK_HOME = '/path/to/spark'  // Path to Spark installation
        DELTA_CORE_JAR = '/path/to/spark/jars/delta-core_2.12-1.0.0.jar'  // Path to Delta core jar
    }

    stages {
        // Stage 1: Checkout the repository with Salesforce and Delta Lake files
        stage('Checkout') {
            steps {
                git url: 'https://github.com/N-P-N-P/Jenkins-SFDX.git', branch: 'main'
            }
        }

        // Stage 2: Install Salesforce CLI (sf) if not already installed
        stage('Install Salesforce CLI (sf)') {
            steps {
                script {
                    sh '''
                        if ! command -v sf &> /dev/null
                        then
                            echo "Salesforce CLI (sf) not found, installing..."
                            curl -L https://developer.salesforce.com/media/salesforce-cli/sf/channels/stable/sf-linux-x64.tar.xz -o sf.tar.xz
                            tar -xvf sf.tar.xz
                            echo "Salesforce CLI binary found. Adding to PATH."
                            chmod +x ./sf/bin/sf
                            export PATH=$PATH:$(pwd)/sf/bin
                        else
                            echo "Salesforce CLI (sf) is already installed."
                        fi
                    '''
                    sh '''
                        echo "Checking Salesforce CLI version..."
                        export PATH=$PATH:$(pwd)/sf/bin  # Ensure it's available
                        sf --version
                    '''
                }
            }
        }

        // Stage 3: Authenticate with Salesforce using JWT
        stage('Authenticate with Salesforce') {
            steps {
                script {
                    withCredentials([
                        file(credentialsId: 'salesforce-jwt-key', variable: 'SFDX_JWT_KEY'),
                        string(credentialsId: 'salesforce-client-id', variable: 'SFDX_CLIENT_ID'),
                        string(credentialsId: 'your-salesforce-username', variable: 'SFDX_USERNAME')
                    ]) {
                        echo "JWT Key File: $SFDX_JWT_KEY"
                        sh '''
                            echo "Authenticating with Salesforce using JWT..."
                            export PATH=$PATH:$(pwd)/sf/bin  # Ensure PATH is set
                            sf force:auth:jwt:grant --clientid $SFDX_CLIENT_ID --jwtkeyfile "$SFDX_JWT_KEY" --username $SFDX_USERNAME --instanceurl $SFDX_INSTANCE_URL
                        '''
                    }
                }
            }
        }

        // Stage 4: Run Delta Lake Job (process data using Spark and Delta)
        stage('Run Delta Lake Data Pipeline') {
            steps {
                script {
                    echo "Running Delta Lake pipeline..."
                    // Run Spark job for Delta processing
                    sh '''
                        export SPARK_HOME=${SPARK_HOME}  # Set Spark home if needed
                        export PYSPARK_PYTHON=python3
                        spark-submit --class org.apache.spark.sql.delta.DeltaTable --master local[4] \
                            --jars ${DELTA_CORE_JAR} \
                            /path/to/your/script/process_data.py  # Python script for processing data
                    '''
                }
            }
        }

        // Stage 5: Run Salesforce Tests
        stage('Run Tests') {
            steps {
                script {
                    sh '''
                        echo "Running Salesforce Apex tests..."
                        sf force:apex:test:run --resultformat human --wait 10
                    '''
                }
            }
        }

        // Stage 6: Deploy to Salesforce (only if tests are successful)
        stage('Deploy to Salesforce') {
            steps {
                script {
                    // Use Delta Deployment for faster deployment (deploy only changed files)
                    sh '''
                        echo "Deploying source to Salesforce..."
                        sf force:source:deploy -p force-app --checkonly --testlevel RunLocalTests
                    '''
                    
                    // Actual deployment
                    sh '''
                        echo "Deploying source to Salesforce..."
                        sf force:source:deploy -p force-app --deploydir deploy --testlevel RunLocalTests
                    '''
                }
            }
        }

        // Stage 7: Post-Deployment Steps
        stage('Post-Deployment') {
            steps {
                script {
                    sh 'sf force:org:display'  // Verify the org details after deployment
                }
            }
        }
    }

    // Post actions
    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed.'
        }
    }
}