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

        //stage('Debug Workspace') {
          //  steps {
            //    sh '''
              //      echo "Listing files in workspace:"
                //    ls -l
                  //  echo "Current working directory:"
                    //pwd
                //'''
            //}
        //}

        stage('Install Dependencies') {
            steps {
                sh '''
                               # Update system and install essential packages
                    sudo apt-get update
                    sudo apt-get install -y unzip curl wget git htop nginx docker.io ansible default-jdk ca-certificates gnupg

                    # Enable and start essential services
                    sudo systemctl enable --now nginx
                    sudo systemctl enable --now docker

                    # Add HashiCorp GPG key and repository
                    wget -qO- https://apt.releases.hashicorp.com/gpg | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

                    # Update system again and install Terraform
                    sudo apt-get update
                    sudo apt install -y terraform 

                    # Handle apt release changes & fix broken packages
                    until sudo apt update --allow-releaseinfo-change -y; do echo 'Retrying apt update...'; sleep 2; done
                    sudo apt --fix-broken install -y

                    # Install AWS CLI
                    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                    unzip -o -q awscliv2.zip
                    sudo ./aws/install --update

                    sudo apt-get update
                    sudo apt-get install -y unzip curl gnupg software-properties-common
                    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
                    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
                    sudo apt-get update
                    sudo apt-get install -y packer
                     packer --version
                    # Add HashiCorp repository
                    #echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

                    # Update package lists and install required packages
                    #sudo apt-get update
                    #sudo apt-get install -y terraform packer

                    # Add HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

        #!/bin/bash

# Install required dependencies
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# Add HashiCorp GPG key securely
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add the HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

# Update package lists
sudo apt-get update

# Install Packer
sudo apt-get install -y packer


                    # Install Jenkins
                    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
                    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
                    sudo apt-get update
                    sudo apt-get install -y jenkins
                    sudo systemctl enable --now jenkins
                '''
            }
        }


        stage('Build AMI with Packer') {
            steps {
                script {
                   sh 'ls -l goldenimage.pkr.hcl || { echo "goldenimage.pkr.hcl not found!"; exit 1; }'

                    sh 'packer init goldenimage.pkr.hcl'

                    def packerOutput = sh(script: 'PACKER_LOG=1 PACKER_LOG_PATH=packer_debug.log packer build -machine-readable goldenimage.pkr.hcl | tee output.log', returnStdout: true).trim()

                    def amiIdMatch = packerOutput.find(/ami-\w{8,17}/)

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
                    def oldAmiId = sh(script: """
                    aws ec2 describe-images --owners self --filters "Name=name,Values=ngnixImage" --query 'Images | sort_by(@, &CreationDate)[0].ImageId' --output text
                    """, returnStdout: true).trim()

                    if (oldAmiId && oldAmiId != "None") {
                        echo "Old AMI ID: ${oldAmiId}"

                        // Deregister the old AMI
                        sh "aws ec2 deregister-image --image-id ${oldAmiId}"

                        // Find and delete the associated snapshot
                        def snapshotId = sh(script: """
                        aws ec2 describe-images --image-ids ${oldAmiId} --query 'Images[0].BlockDeviceMappings[0].Ebs.SnapshotId' --output text
                        """, returnStdout: true).trim()

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
