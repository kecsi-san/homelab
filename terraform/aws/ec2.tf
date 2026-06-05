# Debian 13 official AMI — queried at plan time; no hardcoded AMI ID.
# Owner 136693071363 is the Debian official AWS account.
data "aws_ami" "debian13" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-13-amd64-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Security group — rules managed via aws_security_group_rule below (no inline blocks).
resource "aws_security_group" "ec2" {
  name        = "Linuxbox2016DebianGNULinux8Jessie"
  description = "Linuxbox.hu 2016 new security group for Debian GNU 8 Linux"
  vpc_id      = var.vpc_id

  tags = {
    Name = "homelab-edge"
  }
}

locals {
  # port => { protocol, ipv6, description }
  # ipv6 = false for rules where IPv6 was never configured (Hugo, Wireguard)
  ingress_rules = {
    ssh             = { port = 22,    protocol = "tcp", ipv6 = true,  description = "SSH" }
    smtp            = { port = 25,    protocol = "tcp", ipv6 = true,  description = "SMTP" }
    http            = { port = 80,    protocol = "tcp", ipv6 = true,  description = "HTTP" }
    https           = { port = 443,   protocol = "tcp", ipv6 = true,  description = "HTTPS" }
    smtps           = { port = 465,   protocol = "tcp", ipv6 = true,  description = "SMTPS (legacy)" }
    smtp_submission = { port = 587,   protocol = "tcp", ipv6 = true,  description = "SMTP submission (STARTTLS)" }
    imaps           = { port = 993,   protocol = "tcp", ipv6 = true,  description = "IMAPS" }
    hugo            = { port = 1313,  protocol = "tcp", ipv6 = false, description = "Hugo dev server" }
    jupyter         = { port = 8888,  protocol = "tcp", ipv6 = true,  description = "Jupyter" }
    minecraft_tcp   = { port = 19132, protocol = "tcp", ipv6 = true,  description = "Minecraft TCP" }
    minecraft_udp   = { port = 19132, protocol = "udp", ipv6 = true,  description = "Minecraft UDP" }
    wireguard       = { port = 51820, protocol = "udp", ipv6 = false, description = "Wireguard VPN" }
  }
}

resource "aws_security_group_rule" "ingress" {
  for_each          = local.ingress_rules
  security_group_id = aws_security_group.ec2.id
  type              = "ingress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = each.value.protocol
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = each.value.ipv6 ? ["::/0"] : []
  description       = each.value.description
}

resource "aws_security_group_rule" "egress_ipv4" {
  security_group_id = aws_security_group.ec2.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_ipv6" {
  security_group_id = aws_security_group.ec2.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_instance" "ec2" {
  ami                    = "ami-0636e459be80b841e"
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = var.iam_instance_profile

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 25
    encrypted             = false
    kms_key_id            = null
    delete_on_termination = false
    tags = {
      Name = "t3small.linuxbox.hu-root"
    }
  }

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_type           = "standard"
    volume_size           = 32
    encrypted             = false
    delete_on_termination = false
  }

  # Prevent accidental instance replacement when a newer Debian 13 AMI is published.
  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name         = "t3asmall.linuxbox.hu"
    InstanceType = "t3.small"
  }
}
