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
  sg_name              = "homelab-edge"
  instance_name        = "t3asmall.linuxbox.hu"

  # Matches the real, imported layout of the 2016 instance — do not change.
  root_volume_type      = "gp2"
  root_volume_size      = 25
  root_volume_encrypted = false
  legacy_extra_volumes = {
    "/dev/sdf" = { size = 32, type = "standard" }
  }
}

module "eip" {
  source = "../modules/eip"

  instance_id = module.ec2.instance_id
}

# Phase 6 rebuild target — new instance built up alongside the legacy box,
# cut over (EIP swap) once services + data migration are verified.
module "ec2_edge" {
  source = "../modules/ec2"

  vpc_id               = var.vpc_id
  subnet_id            = var.subnet_id
  key_pair_name        = var.key_pair_name
  instance_type        = var.instance_type
  iam_instance_profile = var.iam_instance_profile
  ingress_rules        = local.ingress_rules
  sg_name              = "homelab-edge-new"
  instance_name        = "edge.kecskemethy.net"

  # Per docs/howtos/ec2-ebs-volumes.md — each service's data on its own
  # independently resizable volume, encrypted (departs from the legacy
  # instance's unencrypted layout above by design).
  root_volume_type      = "gp3"
  root_volume_size      = 20
  root_volume_encrypted = true
  data_volumes = {
    "/dev/sdf" = { size = 40, type = "gp3", encrypted = true, name = "edge.kecskemethy.net-home" }
    "/dev/sdg" = { size = 20, type = "gp3", encrypted = true, name = "edge.kecskemethy.net-www" }
    "/dev/sdh" = { size = 10, type = "gp3", encrypted = true, name = "edge.kecskemethy.net-log" }
  }
}

# Temporary EIP for reachability during build-out; not the production
# 52.48.130.44 address, which stays on the legacy instance until cutover.
module "eip_edge" {
  source = "../modules/eip"

  instance_id = module.ec2_edge.instance_id
  name        = "edge.kecskemethy.net"
}

module "route53" {
  source = "../modules/route53-zone"

  domains        = var.route53_domains
  mail_public_ip = module.eip.public_ip
  mail_ipv6      = var.mail_ipv6
  dkim_keys      = var.dkim_keys
}

module "s3" {
  for_each = toset(var.s3_bucket_names)
  source   = "../modules/s3-bucket"

  bucket_name = each.key
}

# Writes inventory/aws_hosts after every apply so Ansible always has the current EIP.
# This file is gitignored — it contains live IP addresses.
# [aws] stays pointed solely at the production instance; existing ec2-*.yml
# playbooks target that group, so they are unaffected by the rebuild instance.
# Target the new box explicitly, e.g.:
#   ansible-playbook -i inventory/aws_hosts -l aws_edge playbooks/ec2-prerequisite.yml
resource "local_file" "ansible_inventory" {
  content = join("\n", [
    "[aws]",
    "${module.eip.public_ip} ansible_user=${var.admin_user}",
    "",
    "[aws_edge]",
    "${module.eip_edge.public_ip} ansible_user=${var.admin_user}",
    "",
  ])
  filename        = "${path.root}/../../inventory/aws_hosts"
  file_permission = "0600"
}
