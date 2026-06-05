output "ec2_public_ip" {
  description = "Elastic IP of the edge node"
  value       = aws_eip.ec2.public_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.ec2.id
}

output "ec2_ami_id" {
  description = "AMI in use (Debian 13)"
  value       = aws_instance.ec2.ami
}

output "route53_name_servers" {
  description = "NS records per zone — update registrar if zones were recreated"
  value = {
    for domain, zone in aws_route53_zone.zones :
    domain => zone.name_servers
  }
}
