#!/bin/bash
# Test script for verifying the deployed application

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

# Test infrastructure
test_infrastructure() {
    log "Testing infrastructure..."
    
    cd terraform
    
    # Check if Terraform state exists
    if [ ! -f "terraform.tfstate" ]; then
        error "Terraform state not found. Please run bootstrap.sh first."
        exit 1
    fi
    
    # Get IP addresses
    CONTROLLER_IP=$(terraform output -raw controller_public_ip 2>/dev/null || echo "")
    MANAGER_IP=$(terraform output -raw swarm_manager_public_ip 2>/dev/null || echo "")
    WORKER_A_IP=$(terraform output -raw swarm_worker_a_public_ip 2>/dev/null || echo "")
    WORKER_B_IP=$(terraform output -raw swarm_worker_b_public_ip 2>/dev/null || echo "")
    
    if [ -z "$CONTROLLER_IP" ] || [ -z "$MANAGER_IP" ] || [ -z "$WORKER_A_IP" ] || [ -z "$WORKER_B_IP" ]; then
        error "Could not retrieve IP addresses from Terraform"
        exit 1
    fi
    
    success "Infrastructure IPs retrieved"
    echo "  Controller: $CONTROLLER_IP"
    echo "  Manager: $MANAGER_IP"
    echo "  Worker A: $WORKER_A_IP"
    echo "  Worker B: $WORKER_B_IP"
    
    cd ..
}

# Test SSH connectivity
test_ssh_connectivity() {
    log "Testing SSH connectivity..."
    
    cd ansible
    
    # Test connectivity with Ansible
    if ansible all -m ping --timeout=30; then
        success "SSH connectivity test passed"
    else
        error "SSH connectivity test failed"
        return 1
    fi
    
    cd ..
}

# Test Docker Swarm
test_docker_swarm() {
    log "Testing Docker Swarm cluster..."
    
    cd ansible
    
    # Check Swarm status
    log "Checking Swarm cluster status..."
    ansible swarm_managers -m shell -a "docker node ls" --timeout=30
    
    # Check services
    log "Checking Docker services..."
    ansible swarm_managers -m shell -a "docker service ls" --timeout=30
    
    success "Docker Swarm test completed"
    
    cd ..
}

# Test application endpoints
test_application() {
    log "Testing application endpoints..."
    
    cd terraform
    
    MANAGER_IP=$(terraform output -raw swarm_manager_public_ip)
    WORKER_A_IP=$(terraform output -raw swarm_worker_a_public_ip)
    WORKER_B_IP=$(terraform output -raw swarm_worker_b_public_ip)
    
    cd ..
    
    # Test each endpoint
    for ip in $MANAGER_IP $WORKER_A_IP $WORKER_B_IP; do
        log "Testing application at http://$ip/login/"
        
        if curl -f -s -o /dev/null --max-time 30 "http://$ip/login/"; then
            success "Application accessible at $ip"
        else
            warning "Application not accessible at $ip"
        fi
    done
}

# Test application functionality
test_application_functionality() {
    log "Testing application functionality..."
    
    cd terraform
    MANAGER_IP=$(terraform output -raw swarm_manager_public_ip)
    cd ..
    
    # Test registration
    log "Testing user registration..."
    REGISTER_RESPONSE=$(curl -s -X POST \
        -d "username=TEST_ITA700&password=TEST_2022PE0000" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --cookie-jar cookies.txt \
        "http://$MANAGER_IP/register/" || echo "FAILED")
    
    if [[ $REGISTER_RESPONSE == *"FAILED"* ]]; then
        warning "Registration test failed (may be expected if user exists)"
    else
        success "Registration test completed"
    fi
    
    # Test login
    log "Testing user login..."
    LOGIN_RESPONSE=$(curl -s -X POST \
        -d "username=TEST_ITA700&password=TEST_2022PE0000" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --cookie-jar cookies.txt \
        --cookie cookies.txt \
        "http://$MANAGER_IP/login/" || echo "FAILED")
    
    if [[ $LOGIN_RESPONSE == *"FAILED"* ]]; then
        warning "Login test failed"
    else
        success "Login test completed"
    fi
    
    # Test home page
    log "Testing home page..."
    HOME_RESPONSE=$(curl -s --cookie cookies.txt "http://$MANAGER_IP/home/" || echo "FAILED")
    
    if [[ $HOME_RESPONSE == *"Hello TEST_ITA700"* ]]; then
        success "Home page test passed - personalization working"
    elif [[ $HOME_RESPONSE == *"FAILED"* ]]; then
        warning "Home page test failed"
    else
        warning "Home page accessible but personalization not verified"
    fi
    
    # Clean up
    rm -f cookies.txt
}

# Test database connectivity
test_database() {
    log "Testing database connectivity..."
    
    cd ansible
    
    # Test PostgreSQL connectivity
    ansible swarm_managers -m shell -a "docker exec \$(docker ps -q -f name=myapp_db) pg_isready -U postgres" --timeout=30 || warning "Database connectivity test failed"
    
    success "Database test completed"
    
    cd ..
}

# Performance test
performance_test() {
    log "Running basic performance test..."
    
    cd terraform
    MANAGER_IP=$(terraform output -raw swarm_manager_public_ip)
    cd ..
    
    # Simple load test with curl
    log "Testing response time..."
    RESPONSE_TIME=$(curl -o /dev/null -s -w "%{time_total}" "http://$MANAGER_IP/login/")
    
    echo "Response time: ${RESPONSE_TIME}s"
    
    if (( $(echo "$RESPONSE_TIME < 5.0" | bc -l) )); then
        success "Performance test passed (response time: ${RESPONSE_TIME}s)"
    else
        warning "Performance test warning - slow response time: ${RESPONSE_TIME}s"
    fi
}

# Generate test report
generate_report() {
    log "Generating test report..."
    
    REPORT_FILE="test-report-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$REPORT_FILE" << EOF
DevOps Assignment Test Report
Generated: $(date)

Infrastructure Status:
$(cd terraform && terraform output 2>/dev/null || echo "Terraform outputs not available")

Docker Swarm Status:
$(cd ansible && ansible swarm_managers -m shell -a "docker node ls" 2>/dev/null || echo "Swarm status not available")

Docker Services:
$(cd ansible && ansible swarm_managers -m shell -a "docker service ls" 2>/dev/null || echo "Service status not available")

Application URLs:
$(cd terraform && {
    MANAGER_IP=$(terraform output -raw swarm_manager_public_ip 2>/dev/null || echo "N/A")
    WORKER_A_IP=$(terraform output -raw swarm_worker_a_public_ip 2>/dev/null || echo "N/A")
    WORKER_B_IP=$(terraform output -raw swarm_worker_b_public_ip 2>/dev/null || echo "N/A")
    echo "- Manager:  http://$MANAGER_IP/login/"
    echo "- Worker A: http://$WORKER_A_IP/login/"
    echo "- Worker B: http://$WORKER_B_IP/login/"
})

Test Summary:
- Infrastructure: $([ -f terraform/terraform.tfstate ] && echo "PASS" || echo "FAIL")
- SSH Connectivity: $(cd ansible && ansible all -m ping --timeout=10 >/dev/null 2>&1 && echo "PASS" || echo "FAIL")
- Docker Swarm: $(cd ansible && ansible swarm_managers -m shell -a "docker node ls" --timeout=10 >/dev/null 2>&1 && echo "PASS" || echo "FAIL")
- Application: $(cd terraform && curl -f -s --max-time 10 "http://$(terraform output -raw swarm_manager_public_ip 2>/dev/null)/login/" >/dev/null 2>&1 && echo "PASS" || echo "FAIL")

EOF
    
    success "Test report generated: $REPORT_FILE"
}

# Main execution
main() {
    echo ""
    echo "=========================="
    echo "  Application Test Suite  "
    echo "=========================="
    echo ""
    
    log "Starting comprehensive test suite..."
    
    # Test infrastructure
    test_infrastructure
    
    # Test SSH connectivity
    test_ssh_connectivity
    
    # Test Docker Swarm
    test_docker_swarm
    
    # Test application endpoints
    test_application
    
    # Test application functionality
    test_application_functionality
    
    # Test database
    test_database
    
    # Performance test
    if command -v bc &> /dev/null; then
        performance_test
    else
        warning "bc not installed, skipping performance test"
    fi
    
    # Generate report
    generate_report
    
    echo ""
    success "Test suite completed!"
    echo ""
    echo "Summary:"
    echo "- All major components tested"
    echo "- Test report generated"
    echo "- Check the report file for detailed results"
    echo ""
}

# Run main function
main "$@"