locals {
  # ipv6 = false for rules where IPv6 is not applicable (Wireguard)
  ingress_rules = {
    ssh             = { port = 22, protocol = "tcp", ipv6 = true, description = "SSH" }
    smtp            = { port = 25, protocol = "tcp", ipv6 = true, description = "SMTP" }
    http            = { port = 80, protocol = "tcp", ipv6 = true, description = "HTTP" }
    https           = { port = 443, protocol = "tcp", ipv6 = true, description = "HTTPS" }
    smtps           = { port = 465, protocol = "tcp", ipv6 = true, description = "SMTPS (legacy)" }
    smtp_submission = { port = 587, protocol = "tcp", ipv6 = true, description = "SMTP submission (STARTTLS)" }
    imaps           = { port = 993, protocol = "tcp", ipv6 = true, description = "IMAPS" }
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

# SSH bootstrap keypair for the edge node — dedicated (not the shared legacy
# key_pair_name), public half only, read from Vault (never -private; see
# docs/howtos/vault-secrets-architecture.md's addendum on why the two halves
# live at separate Vault paths).
data "vault_kv_secret_v2" "edge_ssh_bootstrap_public" {
  mount = "ec2"
  name  = "ssh-edge-bootstrap-public"
}

resource "aws_key_pair" "edge" {
  key_name   = "linuxbox2026"
  public_key = data.vault_kv_secret_v2.edge_ssh_bootstrap_public.data["public_key"]
}

# Phase 6 rebuild target — new instance built up alongside the legacy box,
# cut over (EIP swap) once services + data migration are verified.
module "ec2_edge" {
  source = "../modules/ec2"

  vpc_id               = var.vpc_id
  subnet_id            = var.subnet_id
  key_pair_name        = aws_key_pair.edge.key_name
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

  # cloud-init renames the default sudo user to edge_ssh_user (kecsi) and
  # formats/mounts the volumes below at first boot — see
  # docs/howtos/ec2-rebuild-plan.md's Phase 6 design-decisions section.
  cloud_init_user_rename = var.edge_ssh_user
  data_volumes = {
    "/dev/sdf" = { size = 40, type = "gp3", encrypted = true, name = "edge.kecskemethy.net-home", mount_path = "/home" }
    "/dev/sdg" = { size = 20, type = "gp3", encrypted = true, name = "edge.kecskemethy.net-www", mount_path = "/var/www" }
    "/dev/sdh" = { size = 10, type = "gp3", encrypted = true, name = "edge.kecskemethy.net-log", mount_path = "/var/log" }
  }
}

# Temporary EIP for reachability during build-out; not the production
# 52.48.130.44 address, which stays on the legacy instance until cutover.
module "eip_edge" {
  source = "../modules/eip"

  instance_id = module.ec2_edge.instance_id
  name        = "edge.kecskemethy.net"
}

# DKIM public keys are generated on the mail server (roles/setup_email-server)
# and backed up to Vault every Ansible run. Reading only the "-public" path
# here — never "-private" — keeps the private key out of this state file; see
# docs/howtos/vault-secrets-architecture.md's DKIM addendum.
data "vault_kv_secret_v2" "dkim_public" {
  for_each = toset(var.route53_domains)
  mount    = "ec2"
  name     = "dkim-public/${each.key}"
}

locals {
  # nonsensitive(): the Vault provider marks an entire KV v2 secret's data map
  # sensitive, but this specific field is a DKIM *public* key — meant to be
  # published in public DNS, nothing to protect. Declassifying it here also
  # lets it be used as a for_each key below (sensitive values are disallowed
  # there) and keeps `terraform plan` output readable for this record instead
  # of showing "(sensitive value)".
  # Filters out any domain Vault doesn't have a value for yet, so the record
  # is simply not created rather than created empty.
  dkim_keys = {
    for d in var.route53_domains : d => nonsensitive(data.vault_kv_secret_v2.dkim_public[d].data["public_key"])
    if nonsensitive(try(data.vault_kv_secret_v2.dkim_public[d].data["public_key"], "")) != ""
  }
}

module "route53" {
  source = "../modules/route53-zone"

  domains        = var.route53_domains
  mail_public_ip = module.eip.public_ip
  mail_ipv6      = var.mail_ipv6
  dkim_keys      = local.dkim_keys
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
    "${module.eip_edge.public_ip} ansible_user=${var.edge_ssh_user}",
    "",
  ])
  filename        = "${path.root}/../../inventory/aws_hosts"
  file_permission = "0600"
}
