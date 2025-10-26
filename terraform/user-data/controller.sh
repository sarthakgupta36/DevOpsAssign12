#!/bin/bash
# User data script for Controller instance

set -e

# Update system
apt-get update
apt-get upgrade -y

# Set hostname
hostnamectl set-hostname ${hostname}
echo "127.0.0.1 ${hostname}" >> /etc/hosts

# Install basic tools
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    python3 \
    python3-pip \
    awscli

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update
apt-get install -y terraform

# Install Ansible
apt-get install -y ansible

# Install Docker (for building images)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create working directory
mkdir -p /home/ubuntu/devops-assignment
chown ubuntu:ubuntu /home/ubuntu/devops-assignment

# Install Jenkins (optional for CI/CD)
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt-get update
apt-get install -y openjdk-11-jdk jenkins

# Start and enable services
systemctl enable docker
systemctl start docker
systemctl enable jenkins
systemctl start jenkins

# Create SSH key for ansible
sudo -u ubuntu ssh-keygen -t rsa -b 4096 -f /home/ubuntu/.ssh/ansible_key -N ""
chown ubuntu:ubuntu /home/ubuntu/.ssh/ansible_key*

# Log completion
echo "Controller setup completed at $(date)" > /var/log/user-data.log