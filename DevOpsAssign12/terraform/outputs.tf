# Terraform outputs for AWS infrastructure

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.main.id
}

output "controller_instance_id" {
  description = "ID of the controller instance"
  value       = aws_instance.controller.id
}

output "controller_public_ip" {
  description = "Public IP of the controller instance"
  value       = aws_eip.controller.public_ip
}

output "controller_private_ip" {
  description = "Private IP of the controller instance"
  value       = aws_instance.controller.private_ip
}

output "swarm_manager_instance_id" {
  description = "ID of the swarm manager instance"
  value       = aws_instance.swarm_manager.id
}

output "swarm_manager_public_ip" {
  description = "Public IP of the swarm manager instance"
  value       = aws_eip.swarm_manager.public_ip
}

output "swarm_manager_private_ip" {
  description = "Private IP of the swarm manager instance"
  value       = aws_instance.swarm_manager.private_ip
}

output "swarm_worker_a_instance_id" {
  description = "ID of the swarm worker A instance"
  value       = aws_instance.swarm_worker_a.id
}

output "swarm_worker_a_public_ip" {
  description = "Public IP of the swarm worker A instance"
  value       = aws_eip.swarm_worker_a.public_ip
}

output "swarm_worker_a_private_ip" {
  description = "Private IP of the swarm worker A instance"
  value       = aws_instance.swarm_worker_a.private_ip
}

output "swarm_worker_b_instance_id" {
  description = "ID of the swarm worker B instance"
  value       = aws_instance.swarm_worker_b.id
}

output "swarm_worker_b_public_ip" {
  description = "Public IP of the swarm worker B instance"
  value       = aws_eip.swarm_worker_b.public_ip
}

output "swarm_worker_b_private_ip" {
  description = "Private IP of the swarm worker B instance"
  value       = aws_instance.swarm_worker_b.private_ip
}

output "key_pair_name" {
  description = "Name of the AWS key pair"
  value       = aws_key_pair.main.key_name
}

output "private_key_path" {
  description = "Path to the private key file"
  value       = local_file.private_key.filename
}

# Summary output for easy reference
output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    vpc_id     = aws_vpc.main.id
    region     = var.aws_region
    instances = {
      controller = {
        id         = aws_instance.controller.id
        public_ip  = aws_eip.controller.public_ip
        private_ip = aws_instance.controller.private_ip
      }
      swarm_manager = {
        id         = aws_instance.swarm_manager.id
        public_ip  = aws_eip.swarm_manager.public_ip
        private_ip = aws_instance.swarm_manager.private_ip
      }
      swarm_worker_a = {
        id         = aws_instance.swarm_worker_a.id
        public_ip  = aws_eip.swarm_worker_a.public_ip
        private_ip = aws_instance.swarm_worker_a.private_ip
      }
      swarm_worker_b = {
        id         = aws_instance.swarm_worker_b.id
        public_ip  = aws_eip.swarm_worker_b.public_ip
        private_ip = aws_instance.swarm_worker_b.private_ip
      }
    }
    key_pair = aws_key_pair.main.key_name
    private_key_file = local_file.private_key.filename
  }
}