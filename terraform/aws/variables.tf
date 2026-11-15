variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_pair_name" {
  description = "AWS EC2 key pair name (must already exist in the region)"
  type        = string
}

variable "admin_user" {
  description = "SSH login user on the EC2 instance (Debian default: admin)"
  type        = string
  default     = "admin"
}

variable "vpc_id" {
  description = "VPC ID where the EC2 instance lives"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile name to attach to the EC2 instance (empty string = none)"
  type        = string
  default     = ""
}

variable "route53_domains" {
  description = "Domains with Route53 hosted zones to manage (MX, SPF, DMARC records created for each)"
  type        = list(string)
}

variable "mail_ipv6" {
  description = "Public IPv6 address of the mail server (for AAAA records)"
  type        = string
  default     = ""
}

variable "s3_bucket_names" {
  description = "Names of existing S3 buckets to import and manage"
  type        = list(string)
  default     = []
}

variable "edge_ssh_user" {
  description = "SSH login user cloud-init creates on edge.kecskemethy.net (renamed from Debian's default sudo user at first boot)"
  type        = string
  default     = "kecsi"
}

variable "vault_address" {
  description = "Vault server address"
  type        = string
}

variable "ses_sender_domains" {
  description = "Sender domains the mail server relays through Amazon SES for Microsoft consumer recipients. Each gets an SES identity with Easy DKIM; those also in route53_domains get their DKIM records created here, the rest are listed in the ses_manual_dns_records output. Empty list = no SES resources."
  type        = list(string)
  default     = []
}

variable "ses_relay_iam_user_name" {
  description = "Name of the IAM user whose access key becomes the Postfix SMTP credentials for SES"
  type        = string
  default     = "postfix-ses-relay"
}

variable "ses_mail_from_subdomain" {
  description = "Subdomain of each SES sender domain used as the custom MAIL FROM (envelope/bounce) domain, e.g. \"ses\" gives ses.example.com. SES sends with a bounce address there and SPF passes for it."
  type        = string
  default     = "ses"
}

variable "edge_instance_type" {
  description = "EC2 instance type of the new edge node (Phase 6 rebuild). Separate from instance_type, which the legacy instance uses, so resizing the edge node never touches the legacy one. The node is stopped between work sessions; to resize, stop it, change this value and apply."
  type        = string
  default     = "t3a.small"
}
