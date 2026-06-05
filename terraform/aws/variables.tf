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

variable "email_domains" {
  description = "Domains handled by the email server (MX records will be created for each)"
  type        = list(string)
  default     = []
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
  description = "IAM instance profile name to attach to the EC2 instance"
  type        = string
  default     = ""
}
