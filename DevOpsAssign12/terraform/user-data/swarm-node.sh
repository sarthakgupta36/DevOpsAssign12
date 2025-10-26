#!/bin/bash
# User data script for Docker Swarm nodes

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
    python3-pip

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Configure Docker daemon for Swarm
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# Start and enable Docker
systemctl enable docker
systemctl start docker

# Create working directory
mkdir -p /home/ubuntu/app
chown ubuntu:ubuntu /home/ubuntu/app

# Install additional monitoring tools
apt-get install -y htop iotop nethogs

# Configure firewall for Docker Swarm
ufw --force enable
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8000/tcp
ufw allow 2377/tcp  # Docker Swarm management
ufw allow 7946/tcp  # Docker Swarm node communication
ufw allow 7946/udp  # Docker Swarm node communication
ufw allow 4789/udp  # Docker Swarm overlay network
ufw allow 5432/tcp  # PostgreSQL

# Log completion
echo "${role} node setup completed at $(date)" > /var/log/user-data.log
echo "Role: ${role}" >> /var/log/user-data.log