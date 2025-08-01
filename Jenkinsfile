pipeline {
    agent any

    environment {
        SPARK_HOME = '/opt/spark'  // Path to Spark installation
        PYSPARK_PYTHON = 'python3'
        LAST_PROCESSED_TIMESTAMP_FILE = '/path/to/last_processed_timestamp.txt'  // Path to store the last processed timestamp
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/N-P-N-P/Jenkins-SFDX.git', branch: 'main'
            }
        }

        stage('Run Incremental Data Processing') {
            steps {
                script {
                    echo "Running incremental data processing..."

                    // Read the last processed timestamp from the file
                    def lastProcessedTimestamp = sh(script: "cat ${LAST_PROCESSED_TIMESTAMP_FILE}", returnStdout: true).trim()

                    // If the file is empty (i.e., first run), set the timestamp to a very old date (or the beginning of the dataset)
                    if (!lastProcessedTimestamp) {
                        lastProcessedTimestamp = '1970-01-01T00:00:00'
                    }

                    // Run the Spark job to process only the new/updated data since the last processed timestamp
                    sh '''
                        export SPARK_HOME='/opt/spark'
                        export PATH=$PATH:$SPARK_HOME/bin

                        echo "Verifying Spark installation..."
                        spark-submit --version  # Ensure spark-submit is available

                        # Running incremental data processing based on the last processed timestamp
                        spark-submit --class org.apache.spark.sql.SparkSession \
                            --master local[4] \
                            --conf "spark.sql.warehouse.dir=/tmp/spark-warehouse" \
                            --py-files ${WORKSPACE}/scripts/process_incremental_data.py \
                            -- ${lastProcessedTimestamp}  # Pass the last processed timestamp as argument to your script
                    '''
                }
            }
        }

        stage('Update Last Processed Timestamp') {
            steps {
                script {
                    echo "Updating last processed timestamp..."

                    // Fetch the most recent timestamp from the processed data (this could be the max timestamp from the last batch)
                    def newTimestamp = sh(script: "python3 ${WORKSPACE}/scripts/fetch_latest_timestamp.py", returnStdout: true).trim()

                    // Update the last processed timestamp file with the new timestamp
                    writeFile file: LAST_PROCESSED_TIMESTAMP_FILE, text: newTimestamp
                }
            }
        }
    }

    post {
        success {
            echo 'Incremental data processing completed successfully.'
        }
        failure {
            echo 'Incremental data processing failed.'
        }
    }
}