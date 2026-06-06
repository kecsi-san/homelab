output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "ami_id" {
  description = "AMI in use (Debian 13)"
  value       = aws_instance.this.ami
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.this.id
}
