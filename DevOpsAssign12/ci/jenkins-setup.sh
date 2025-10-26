#!/bin/bash
# Jenkins setup script for the DevOps assignment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Install Jenkins
install_jenkins() {
    log "Installing Jenkins..."
    
    # Update system
    sudo apt-get update
    
    # Install Java
    sudo apt-get install -y openjdk-11-jdk
    
    # Add Jenkins repository
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
    sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    
    # Install Jenkins
    sudo apt-get update
    sudo apt-get install -y jenkins
    
    # Start and enable Jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    
    success "Jenkins installed successfully"
}

# Install additional tools
install_tools() {
    log "Installing additional tools..."
    
    # Install Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Add jenkins user to docker group
    sudo usermod -aG docker jenkins
    
    # Install Terraform
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update
    sudo apt-get install -y terraform
    
    # Install Ansible
    sudo apt-get install -y ansible
    
    # Install AWS CLI
    sudo apt-get install -y awscli
    
    # Install additional tools
    sudo apt-get install -y git curl wget unzip python3 python3-pip
    
    success "Additional tools installed"
}

# Configure Jenkins
configure_jenkins() {
    log "Configuring Jenkins..."
    
    # Wait for Jenkins to start
    sleep 30
    
    # Get initial admin password
    JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
    
    echo ""
    success "Jenkins setup completed!"
    echo ""
    echo "Jenkins is now running on: http://localhost:8080"
    echo "Initial admin password: $JENKINS_PASSWORD"
    echo ""
    echo "Next steps:"
    echo "1. Open http://localhost:8080 in your browser"
    echo "2. Enter the initial admin password: $JENKINS_PASSWORD"
    echo "3. Install suggested plugins"
    echo "4. Create an admin user"
    echo "5. Configure the following plugins:"
    echo "   - Pipeline"
    echo "   - Git"
    echo "   - Docker Pipeline"
    echo "   - AWS Steps"
    echo "   - Ansible"
    echo "   - Email Extension"
    echo ""
    echo "6. Add credentials:"
    echo "   - AWS Access Key (ID: aws-credentials)"
    echo "   - SSH Private Key (ID: terraform-ssh-key)"
    echo ""
    echo "7. Create a new Pipeline job using the Jenkinsfile from ci/Jenkinsfile"
    echo ""
}

# Create Jenkins job configuration
create_job_config() {
    log "Creating Jenkins job configuration..."
    
    cat > jenkins-job-config.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobAction plugin="pipeline-model-definition@1.8.5"/>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction plugin="pipeline-model-definition@1.8.5">
      <jobProperties/>
      <triggers/>
      <parameters/>
      <options/>
    </org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction>
  </actions>
  <description>DevOps Assignment - Django Application Deployment Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.34.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.92">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.2">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/YOUR_USERNAME/DevOps_Assignment.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
        <hudson.plugins.git.BranchSpec>
          <name>*/ITA*</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>ci/Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
    
    success "Jenkins job configuration created: jenkins-job-config.xml"
    echo "Import this configuration when creating a new Pipeline job in Jenkins"
}

# Setup GitHub webhook
setup_github_webhook() {
    log "Setting up GitHub webhook instructions..."
    
    echo ""
    echo "To set up GitHub webhook:"
    echo "1. Go to your GitHub repository settings"
    echo "2. Click on 'Webhooks' in the left sidebar"
    echo "3. Click 'Add webhook'"
    echo "4. Set Payload URL to: http://YOUR_JENKINS_URL:8080/github-webhook/"
    echo "5. Set Content type to: application/json"
    echo "6. Select 'Just the push event'"
    echo "7. Make sure 'Active' is checked"
    echo "8. Click 'Add webhook'"
    echo ""
}

# Main execution
main() {
    echo ""
    echo "================================"
    echo "  Jenkins Setup for DevOps     "
    echo "================================"
    echo ""
    
    log "Starting Jenkins setup..."
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        error "Please don't run this script as root"
        exit 1
    fi
    
    # Install Jenkins
    install_jenkins
    
    # Install additional tools
    install_tools
    
    # Configure Jenkins
    configure_jenkins
    
    # Create job configuration
    create_job_config
    
    # Setup webhook instructions
    setup_github_webhook
    
    success "Jenkins setup completed!"
}

# Run main function
main "$@"