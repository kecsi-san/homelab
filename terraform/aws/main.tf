locals {
  # ipv6 = false for rules where IPv6 is not applicable (Wireguard)
  ingress_rules = {
    ssh             = { port = 22,    protocol = "tcp", ipv6 = true,  description = "SSH" }
    smtp            = { port = 25,    protocol = "tcp", ipv6 = true,  description = "SMTP" }
    http            = { port = 80,    protocol = "tcp", ipv6 = true,  description = "HTTP" }
    https           = { port = 443,   protocol = "tcp", ipv6 = true,  description = "HTTPS" }
    smtps           = { port = 465,   protocol = "tcp", ipv6 = true,  description = "SMTPS (legacy)" }
    smtp_submission = { port = 587,   protocol = "tcp", ipv6 = true,  description = "SMTP submission (STARTTLS)" }
    imaps           = { port = 993,   protocol = "tcp", ipv6 = true,  description = "IMAPS" }
    wireguard       = { port = 51820, protocol = "udp", ipv6 = false, description = "Wireguard VPN" }
  }
}

module "ec2" {
  source = "../modules/ec2"

  vpc_id               = var.vpc_id
  subnet_id            = var.subnet_id
  key_pair_name        = var.key_pair_name
  instance_type        = var.instance_type
  iam_instance_profile = var.iam_instance_profile
  ingress_rules        = local.ingress_rules
}

module "eip" {
  source = "../modules/eip"

  instance_id = module.ec2.instance_id
}

module "route53" {
  source = "../modules/route53-zone"

  domains        = var.route53_domains
  mail_hostname  = var.mail_hostname
  mail_public_ip = module.eip.public_ip
}

module "s3" {
  for_each = toset(var.s3_bucket_names)
  source   = "../modules/s3-bucket"

  bucket_name = each.key
}

# Writes inventory/aws_hosts after every apply so Ansible always has the current EIP.
# This file is gitignored — it contains the live IP address.
resource "local_file" "ansible_inventory" {
  content         = "[aws]\n${module.eip.public_ip} ansible_user=${var.admin_user}\n"
  filename        = "${path.root}/../../inventory/aws_hosts"
  file_permission = "0600"
}
