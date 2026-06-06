variable "instance_id" {
  description = "EC2 instance ID to associate the EIP with"
  type        = string
}

variable "name" {
  description = "Name tag for the EIP"
  type        = string
  default     = "linuxbox.hu"
}
