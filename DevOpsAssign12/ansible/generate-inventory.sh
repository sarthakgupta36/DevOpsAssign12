#!/bin/bash
# Generate Ansible inventory from Terraform outputs

set -e

TERRAFORM_DIR="../terraform"
INVENTORY_FILE="inventory/hosts.yml"

echo "Generating Ansible inventory from Terraform outputs..."

# Check if terraform directory exists
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "Error: Terraform directory not found at $TERRAFORM_DIR"
    exit 1
fi

# Get Terraform outputs
cd "$TERRAFORM_DIR"

if [ ! -f "terraform.tfstate" ]; then
    echo "Error: Terraform state file not found. Please run 'terraform apply' first."
    exit 1
fi

# Extract IP addresses from Terraform outputs
CONTROLLER_IP=$(terraform output -raw controller_public_ip 2>/dev/null || echo "")
MANAGER_IP=$(terraform output -raw swarm_manager_public_ip 2>/dev/null || echo "")
WORKER_A_IP=$(terraform output -raw swarm_worker_a_public_ip 2>/dev/null || echo "")
WORKER_B_IP=$(terraform output -raw swarm_worker_b_public_ip 2>/dev/null || echo "")

# Go back to ansible directory
cd - > /dev/null

# Check if we got all IPs
if [ -z "$CONTROLLER_IP" ] || [ -z "$MANAGER_IP" ] || [ -z "$WORKER_A_IP" ] || [ -z "$WORKER_B_IP" ]; then
    echo "Error: Could not retrieve all IP addresses from Terraform outputs"
    echo "Controller IP: $CONTROLLER_IP"
    echo "Manager IP: $MANAGER_IP"
    echo "Worker A IP: $WORKER_A_IP"
    echo "Worker B IP: $WORKER_B_IP"
    exit 1
fi

# Generate inventory file
cat > "$INVENTORY_FILE" << EOF
# Ansible inventory for DevOps assignment infrastructure
# Generated from Terraform outputs on $(date)

all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ../terraform/terraform-key.pem
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    
  children:
    controller:
      hosts:
        controller:
          ansible_host: $CONTROLLER_IP
          role: controller
          
    swarm_managers:
      hosts:
        swarm-manager:
          ansible_host: $MANAGER_IP
          role: swarm-manager
          swarm_role: manager
          
    swarm_workers:
      hosts:
        swarm-worker-a:
          ansible_host: $WORKER_A_IP
          role: swarm-worker
          swarm_role: worker
          
        swarm-worker-b:
          ansible_host: $WORKER_B_IP
          role: swarm-worker
          swarm_role: worker
          
    swarm_nodes:
      children:
        swarm_managers:
        swarm_workers:
EOF

echo "Inventory file generated successfully at $INVENTORY_FILE"
echo ""
echo "IP Addresses:"
echo "  Controller: $CONTROLLER_IP"
echo "  Manager: $MANAGER_IP"
echo "  Worker A: $WORKER_A_IP"
echo "  Worker B: $WORKER_B_IP"
echo ""
echo "To test connectivity, run:"
echo "  ansible all -m ping"