pipeline {
    agent any

    environment {
        AWS_REGION = "eu-north-1"
        AWS_ACCOUNT_ID = "296062592493"  // Replace with your AWS account ID if needed
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/AditiRaghav7/AMI-project.git' // Update with your repo
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                sudo apt-get update
                sudo apt-get install -y unzip
                curl -LO https://releases.hashicorp.com/packer/1.8.2/packer_1.8.2_linux_amd64.zip
                unzip packer_1.8.2_linux_amd64.zip
                sudo mv packer /usr/local/bin/
                sudo apt-get install -y awscli
                '''
            }
        }

        stage('Build AMI with Packer') {
            steps {
                script {
                    def packerOutput = sh(script: 'packer build -machine-readable packer.pkr.hcl | tee output.log', returnStdout: true).trim()
                    def amiIdMatch = packerOutput.find(/ami-.{17}/)
                    
                    if (amiIdMatch) {
                        env.NEW_AMI_ID = amiIdMatch
                        echo "New AMI ID: ${env.NEW_AMI_ID}"
                    } else {
                        error "AMI ID not found in Packer output!"
                    }
                }
            }
        }

        stage('Find and Deregister Old AMI') {
            steps {
                script {
                    def oldAmiId = sh(script: '''
                    aws ec2 describe-images --owners self --filters "Name=name,Values=ngnixImage" --query 'Images | sort_by(@, &CreationDate)[0].ImageId' --output text
                    ''', returnStdout: true).trim()

                    if (oldAmiId && oldAmiId != "None") {
                        echo "Old AMI ID: ${oldAmiId}"

                        // Deregister the old AMI
                        sh "aws ec2 deregister-image --image-id ${oldAmiId}"

                        // Find and delete the associated snapshot
                        def snapshotId = sh(script: '''
                        aws ec2 describe-images --image-ids ''' + oldAmiId + ''' --query 'Images[0].BlockDeviceMappings[0].Ebs.SnapshotId' --output text
                        ''', returnStdout: true).trim()

                        if (snapshotId && snapshotId != "None") {
                            echo "Deleting Snapshot: ${snapshotId}"
                            sh "aws ec2 delete-snapshot --snapshot-id ${snapshotId}"
                        }
                    } else {
                        echo "No previous AMI found, skipping deregistration."
                    }
                }
            }
        }
    }

    post {
        success {
            echo "AMI creation and cleanup completed successfully!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
+
