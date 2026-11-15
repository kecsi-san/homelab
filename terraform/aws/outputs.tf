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

output "ses_dkim_manual_records" {
  description = "SES DKIM CNAME records to add by hand, per sender domain whose DNS is not in Route53. Add all three per domain; SES verifies the domain once they resolve."
  value = {
    for domain in local.ses_manual_domains : domain => [
      for token in local.ses_dkim_tokens[domain] : {
        name  = "${token}._domainkey.${domain}"
        type  = "CNAME"
        value = "${token}.dkim.amazonses.com"
      }
    ]
  }
}

output "ses_smtp_endpoint" {
  description = "SES SMTP host for the Postfix relay (port 587, STARTTLS)"
  value       = "email-smtp.${var.aws_region}.amazonaws.com"
}

output "ses_relay_iam_user" {
  description = "IAM user to create the SMTP access key for (empty when no SES domains are configured)"
  value       = try(aws_iam_user.ses_relay[0].name, "")
}
