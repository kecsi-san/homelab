output "ec2_public_ip" {
  description = "Elastic IP of the edge node"
  value       = module.eip.public_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "ec2_ami_id" {
  description = "AMI in use (Debian 13)"
  value       = module.ec2.ami_id
}

output "route53_name_servers" {
  description = "NS records per zone — verify with registrar if zones were recreated"
  value       = module.route53.name_servers
}

output "ec2_edge_public_ip" {
  description = "Temporary EIP of the new Phase 6 rebuild instance (edge.kecskemethy.net)"
  value       = module.eip_edge.public_ip
}

output "ec2_edge_instance_id" {
  description = "Instance ID of the new Phase 6 rebuild instance"
  value       = module.ec2_edge.instance_id
}
