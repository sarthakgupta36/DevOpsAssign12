# Main Terraform configuration for AWS infrastructure
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-20.04-lts-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Create public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Create route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Associate route table with public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "main" {
  name_prefix = "${var.project_name}-sg"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # Django development server
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Django development server"
  }

  # Docker Swarm - Manager
  ingress {
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Docker Swarm management"
  }

  # Docker Swarm - Node communication
  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Docker Swarm node communication TCP"
  }

  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Docker Swarm node communication UDP"
  }

  # Docker Swarm - Overlay network
  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Docker Swarm overlay network"
  }

  # PostgreSQL
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "PostgreSQL database"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-security-group"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Generate SSH key pair
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-keypair"
  public_key = tls_private_key.main.public_key_openssh

  tags = {
    Name        = "${var.project_name}-keypair"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Save private key to local file
resource "local_file" "private_key" {
  content  = tls_private_key.main.private_key_pem
  filename = "${path.module}/terraform-key.pem"
  file_permission = "0600"
}

# Controller instance
resource "aws_instance" "controller" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = aws_subnet.public.id

  user_data = base64encode(templatefile("${path.module}/user-data/controller.sh", {
    hostname = "controller"
  }))

  tags = {
    Name        = "${var.project_name}-controller"
    Role        = "controller"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Swarm Manager instance
resource "aws_instance" "swarm_manager" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = aws_subnet.public.id

  user_data = base64encode(templatefile("${path.module}/user-data/swarm-node.sh", {
    hostname = "swarm-manager"
    role     = "manager"
  }))

  tags = {
    Name        = "${var.project_name}-swarm-manager"
    Role        = "swarm-manager"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Swarm Worker A instance
resource "aws_instance" "swarm_worker_a" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = aws_subnet.public.id

  user_data = base64encode(templatefile("${path.module}/user-data/swarm-node.sh", {
    hostname = "swarm-worker-a"
    role     = "worker"
  }))

  tags = {
    Name        = "${var.project_name}-swarm-worker-a"
    Role        = "swarm-worker"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Swarm Worker B instance
resource "aws_instance" "swarm_worker_b" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = aws_subnet.public.id

  user_data = base64encode(templatefile("${path.module}/user-data/swarm-node.sh", {
    hostname = "swarm-worker-b"
    role     = "worker"
  }))

  tags = {
    Name        = "${var.project_name}-swarm-worker-b"
    Role        = "swarm-worker"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Elastic IPs
resource "aws_eip" "controller" {
  instance = aws_instance.controller.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-controller-eip"
    Project     = var.project_name
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_eip" "swarm_manager" {
  instance = aws_instance.swarm_manager.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-swarm-manager-eip"
    Project     = var.project_name
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_eip" "swarm_worker_a" {
  instance = aws_instance.swarm_worker_a.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-swarm-worker-a-eip"
    Project     = var.project_name
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_eip" "swarm_worker_b" {
  instance = aws_instance.swarm_worker_b.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-swarm-worker-b-eip"
    Project     = var.project_name
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}