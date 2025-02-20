packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "goldenImage"
  instance_type = "t3.micro"
  region        = "eu-north-1"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners = ["099720109477"]  # Canonical's official Ubuntu AMI owner ID
  }

  ssh_username  = "ubuntu"

  subnet_id     = "subnet-05d13b3f0de0754d5"  # Your subnet ID
  vpc_id        = "vpc-0ca519aed94eac2be"  # Your VPC ID
}

build {
  name    = "londonIAC"
  sources = ["source.amazon-ebs.ubuntu"]
  provisioner "shell" {
    inline = [
       "wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list",
       "sudo apt-get update",
      "sudo apt-get install git",
        "sudo apt update && sudo apt upgrade -y",
      "sudo apt install -y htop",
      "sudo apt update && sudo apt install terraform -y",
      "until sudo apt update --allow-releaseinfo-change -y; do echo 'Retrying apt update...'; sleep 2; done",
      "sudo apt --fix-broken install -y",
      "sudo apt install -y unzip",
      "sudo apt install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx",
      "sudo apt install -y docker.io",
      "sudo systemctl enable --now docker",
      "sudo apt install -y curl wget",
      "curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\"",
      "unzip awscliv2.zip",
      "sudo ./aws/install",
      "sudo apt install -y ansible",
      "sudo apt install -y default-jdk",
      "sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key",
      "echo \"deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/\" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y jenkins",
      "sudo systemctl enable --now jenkins"
    ]
  }
}

