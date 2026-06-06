variable "vpc_id" {
  description = "VPC ID for the security group"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the instance"
  type        = string
}

variable "key_pair_name" {
  description = "AWS EC2 key pair name (must already exist in the region)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "iam_instance_profile" {
  description = "IAM instance profile name to attach (empty string = none)"
  type        = string
  default     = ""
}

variable "ingress_rules" {
  description = "Map of ingress rules: key => { port, protocol, ipv6, description }"
  type = map(object({
    port        = number
    protocol    = string
    ipv6        = bool
    description = string
  }))
}
