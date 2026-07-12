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

variable "dkim_keys" {
  description = "Map of domain => full DKIM TXT record value (public key); wildcard *._domainkey record created per entry"
  type        = map(string)
  default     = {}
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
  default     = "https://vault.kecskemethy.hu"
}
