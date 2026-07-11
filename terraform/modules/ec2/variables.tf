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

variable "sg_name" {
  description = "Security group name (must be unique per VPC)"
  type        = string
}

variable "instance_name" {
  description = "Name tag for the instance and its root volume (root volume gets a \"-root\" suffix)"
  type        = string
}

variable "root_volume_type" {
  description = "Root volume EBS type"
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
}

variable "root_volume_encrypted" {
  description = "Whether the root volume is encrypted"
  type        = bool
}

variable "legacy_extra_volumes" {
  description = "Additional volumes declared inline via ebs_block_device, tied to the instance's lifecycle (legacy pattern — matches the imported 2016 instance's real layout). New instances should use data_volumes instead so volumes can be resized independently; see docs/howtos/ec2-ebs-volumes.md."
  type = map(object({
    size = number
    type = string
  }))
  default = {}
}

variable "data_volumes" {
  description = "Additional volumes declared as standalone aws_ebs_volume + aws_volume_attachment resources, keyed by device name (AWS API name, e.g. \"/dev/sdf\") — resizable independently of the instance. See docs/howtos/ec2-ebs-volumes.md."
  type = map(object({
    size      = number
    type      = string
    encrypted = bool
    name      = string
  }))
  default = {}
}
