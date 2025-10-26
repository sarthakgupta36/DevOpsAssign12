#!/bin/bash
# Bootstrap script for complete DevOps automation deployment
# This script provisions infrastructure, configures servers, and deploys the application

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

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if ansible is installed
    if ! command -v ansible &> /dev/null; then
        error "Ansible is not installed. Please install Ansible first."
        exit 1
    fi
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Check if docker is installed (for building images)
    if ! command -v docker &> /dev/null; then
        warning "Docker is not installed locally. Images will be built on remote servers."
    fi
    
    success "All prerequisites checked"
}

# Provision infrastructure with Terraform
provision_infrastructure() {
    log "Provisioning AWS infrastructure with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    log "Initializing Terraform..."
    terraform init
    
    # Validate configuration
    log "Validating Terraform configuration..."
    terraform validate
    
    # Plan deployment
    log "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    # Apply configuration
    log "Applying Terraform configuration..."
    terraform apply -auto-approve tfplan
    
    # Clean up plan file
    rm -f tfplan
    
    success "Infrastructure provisioned successfully"
    
    # Display outputs
    log "Infrastructure details:"
    terraform output
    
    cd ..
}

# Configure servers with Ansible
configure_servers() {
    log "Configuring servers with Ansible..."
    
    cd ansible
    
    # Generate inventory from Terraform outputs
    log "Generating Ansible inventory..."
    chmod +x generate-inventory.sh
    ./generate-inventory.sh
    
    # Wait for instances to be ready
    log "Waiting for instances to be ready..."
    sleep 60
    
    # Test connectivity
    log "Testing connectivity to all servers..."
    ansible all -m ping --timeout=30 || {
        warning "Some servers are not ready yet. Waiting additional 60 seconds..."
        sleep 60
        ansible all -m ping --timeout=30
    }
    
    # Run main playbook
    log "Running Ansible playbooks..."
    ansible-playbook playbooks/site.yml
    
    success "Server configuration completed"
    
    cd ..
}

# Deploy application
deploy_application() {
    log "Deploying application to Docker Swarm..."
    
    cd ansible
    
    # Run deployment playbook
    ansible-playbook playbooks/swarm-deploy.yml
    
    success "Application deployed successfully"
    
    # Get application URLs
    log "Getting application access information..."
    MANAGER_IP=$(cd ../terraform && terraform output -raw swarm_manager_public_ip)
    WORKER_A_IP=$(cd ../terraform && terraform output -raw swarm_worker_a_public_ip)
    WORKER_B_IP=$(cd ../terraform && terraform output -raw swarm_worker_b_public_ip)
    
    echo ""
    success "Application is now accessible at:"
    echo "  - Manager:  http://$MANAGER_IP/login/"
    echo "  - Worker A: http://$WORKER_A_IP/login/"
    echo "  - Worker B: http://$WORKER_B_IP/login/"
    echo ""
    
    cd ..
}

# Setup CI/CD (optional)
setup_cicd() {
    log "Setting up CI/CD pipeline..."
    
    # Check if GitHub Actions workflow exists
    if [ -f ".github/workflows/deploy.yml" ]; then
        log "GitHub Actions workflow found"
        
        # Check if repository is connected to GitHub
        if git remote get-url origin &> /dev/null; then
            REPO_URL=$(git remote get-url origin)
            log "Repository URL: $REPO_URL"
            
            # Push current branch to trigger initial workflow
            CURRENT_BRANCH=$(git branch --show-current)
            log "Pushing to branch: $CURRENT_BRANCH"
            
            git add .
            git commit -m "Initial deployment via bootstrap script" || true
            git push origin "$CURRENT_BRANCH" || warning "Could not push to remote repository"
            
            success "CI/CD pipeline setup completed"
        else
            warning "No Git remote configured. Skipping CI/CD trigger."
        fi
    else
        warning "No GitHub Actions workflow found. Skipping CI/CD setup."
    fi
}

# Cleanup function
cleanup() {
    log "Cleaning up temporary files..."
    
    # Remove Terraform plan files
    rm -f terraform/tfplan
    
    # Remove any temporary Ansible files
    rm -f ansible/.retry
    
    success "Cleanup completed"
}

# Main execution
main() {
    echo ""
    echo "======================================"
    echo "  DevOps Assignment Bootstrap Script  "
    echo "======================================"
    echo ""
    
    log "Starting complete deployment process..."
    
    # Check prerequisites
    check_prerequisites
    
    # Provision infrastructure
    provision_infrastructure
    
    # Configure servers
    configure_servers
    
    # Deploy application
    deploy_application
    
    # Setup CI/CD (optional)
    if [ "$1" = "--with-cicd" ]; then
        setup_cicd
    fi
    
    # Cleanup
    cleanup
    
    echo ""
    success "Bootstrap process completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Test the application by visiting the URLs above"
    echo "2. Register a new user (e.g., ITA700 / 2022PE0000)"
    echo "3. Login and verify the home page displays correctly"
    echo "4. Check Docker Swarm status: ssh -i terraform/terraform-key.pem ubuntu@<manager_ip> 'docker service ls'"
    echo "5. Scale services if needed: ssh -i terraform/terraform-key.pem ubuntu@<manager_ip> 'docker service scale myapp_web=3'"
    echo ""
    echo "To destroy the infrastructure when done:"
    echo "  cd terraform && terraform destroy"
    echo ""
}

# Handle script interruption
trap cleanup EXIT

# Run main function
main "$@"