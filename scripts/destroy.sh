#!/bin/bash
# Destroy script for cleaning up AWS infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Confirm destruction
confirm_destruction() {
    echo ""
    warning "This will destroy ALL AWS resources created by Terraform!"
    echo ""
    echo "Resources to be destroyed:"
    echo "  - 4 EC2 instances (Controller, Manager, Worker A, Worker B)"
    echo "  - 4 Elastic IP addresses"
    echo "  - VPC, subnets, security groups, and networking components"
    echo "  - SSH key pair"
    echo ""
    
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        log "Destruction cancelled by user"
        exit 0
    fi
}

# Remove Docker stacks (optional cleanup)
cleanup_docker_stacks() {
    log "Attempting to clean up Docker stacks..."
    
    cd ansible
    
    # Check if inventory exists
    if [ -f "inventory/hosts.yml" ]; then
        # Try to remove Docker stacks before destroying infrastructure
        log "Removing Docker stacks from Swarm cluster..."
        ansible swarm_managers -m shell -a "docker stack rm myapp" --timeout=30 || warning "Could not remove Docker stacks (instances may already be stopped)"
        
        # Wait for stack removal
        sleep 30
    else
        warning "Ansible inventory not found, skipping Docker cleanup"
    fi
    
    cd ..
}

# Destroy infrastructure
destroy_infrastructure() {
    log "Destroying AWS infrastructure..."
    
    cd terraform
    
    # Check if Terraform state exists
    if [ ! -f "terraform.tfstate" ]; then
        warning "No Terraform state file found. Nothing to destroy."
        cd ..
        return
    fi
    
    # Show what will be destroyed
    log "Planning destruction..."
    terraform plan -destroy
    
    echo ""
    read -p "Proceed with destruction? (type 'yes' to confirm): " final_confirmation
    
    if [ "$final_confirmation" != "yes" ]; then
        log "Destruction cancelled by user"
        cd ..
        exit 0
    fi
    
    # Destroy infrastructure
    log "Destroying infrastructure..."
    terraform destroy -auto-approve
    
    success "Infrastructure destroyed successfully"
    
    cd ..
}

# Clean up local files
cleanup_local_files() {
    log "Cleaning up local files..."
    
    # Remove generated SSH key
    if [ -f "terraform/terraform-key.pem" ]; then
        rm -f terraform/terraform-key.pem
        log "Removed SSH private key"
    fi
    
    # Remove Terraform state backup files
    rm -f terraform/terraform.tfstate.backup
    rm -f terraform/.terraform.lock.hcl
    
    # Remove Ansible retry files
    rm -f ansible/.retry
    
    # Reset Ansible inventory to template
    if [ -f "ansible/inventory/hosts.yml" ]; then
        cat > ansible/inventory/hosts.yml << 'EOF'
# Ansible inventory for DevOps assignment infrastructure
# This file will be populated with Terraform outputs

all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ../terraform/terraform-key.pem
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    
  children:
    controller:
      hosts:
        controller:
          ansible_host: "{{ controller_ip | default('CONTROLLER_IP_PLACEHOLDER') }}"
          role: controller
          
    swarm_managers:
      hosts:
        swarm-manager:
          ansible_host: "{{ manager_ip | default('MANAGER_IP_PLACEHOLDER') }}"
          role: swarm-manager
          swarm_role: manager
          
    swarm_workers:
      hosts:
        swarm-worker-a:
          ansible_host: "{{ worker_a_ip | default('WORKER_A_IP_PLACEHOLDER') }}"
          role: swarm-worker
          swarm_role: worker
          
        swarm-worker-b:
          ansible_host: "{{ worker_b_ip | default('WORKER_B_IP_PLACEHOLDER') }}"
          role: swarm-worker
          swarm_role: worker
          
    swarm_nodes:
      children:
        swarm_managers:
        swarm_workers:
EOF
        log "Reset Ansible inventory to template"
    fi
    
    success "Local cleanup completed"
}

# Main execution
main() {
    echo ""
    echo "=================================="
    echo "  Infrastructure Destroy Script  "
    echo "=================================="
    echo ""
    
    # Confirm destruction
    confirm_destruction
    
    # Clean up Docker stacks first
    if [ "$1" != "--skip-docker-cleanup" ]; then
        cleanup_docker_stacks
    fi
    
    # Destroy infrastructure
    destroy_infrastructure
    
    # Clean up local files
    cleanup_local_files
    
    echo ""
    success "Destruction process completed!"
    echo ""
    echo "All AWS resources have been destroyed."
    echo "Local files have been cleaned up."
    echo ""
    echo "To redeploy, run:"
    echo "  ./scripts/bootstrap.sh"
    echo ""
}

# Run main function
main "$@"