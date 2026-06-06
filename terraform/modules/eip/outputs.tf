output "public_ip" {
  description = "Elastic IP address"
  value       = aws_eip.this.public_ip
}

output "allocation_id" {
  description = "EIP allocation ID"
  value       = aws_eip.this.id
}
