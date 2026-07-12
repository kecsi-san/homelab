# Debian 13 official AMI — queried at plan time; no hardcoded AMI ID.
# Owner 136693071363 is the Debian official AWS account.
data "aws_subnet" "this" {
  id = var.subnet_id
}

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
resource "aws_security_group" "this" {
  name        = var.sg_name
  description = "Homelab edge node security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = var.sg_name
  }
}

resource "aws_security_group_rule" "ingress" {
  for_each          = var.ingress_rules
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = each.value.protocol
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = each.value.ipv6 ? ["::/0"] : []
  description       = each.value.description
}

resource "aws_security_group_rule" "egress_ipv4" {
  security_group_id = aws_security_group.this.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_ipv6" {
  security_group_id = aws_security_group.this.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.debian13.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = var.iam_instance_profile

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    encrypted             = var.root_volume_encrypted
    kms_key_id            = null
    delete_on_termination = false
    tags = {
      Name = "${var.instance_name}-root"
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.legacy_extra_volumes
    content {
      device_name           = ebs_block_device.key
      volume_type           = ebs_block_device.value.type
      volume_size           = ebs_block_device.value.size
      encrypted             = false
      delete_on_termination = false
    }
  }

  # Prevent accidental instance replacement when a newer Debian 13 AMI is published.
  lifecycle {
    ignore_changes = [ami]
  }

  user_data = local.rendered_user_data

  tags = {
    Name         = var.instance_name
    InstanceType = var.instance_type
  }
}

# Data volumes resizable independently of the instance — see docs/howtos/ec2-ebs-volumes.md.
# AZ comes from the subnet, not the instance, so these don't depend on aws_instance.this —
# that lets the instance's own user_data reference these volumes' IDs (by-id device paths
# for cloud-init) without creating a dependency cycle.
resource "aws_ebs_volume" "data" {
  for_each          = var.data_volumes
  availability_zone = data.aws_subnet.this.availability_zone
  size              = each.value.size
  type              = each.value.type
  encrypted         = each.value.encrypted

  tags = {
    Name = each.value.name
  }
}

locals {
  # Only volumes with mount_path set get formatted/mounted by cloud-init.
  # Identified via /dev/disk/by-id — deterministic, keyed off the volume's own
  # ID — since Nitro instances don't reliably expose AWS's requested device
  # names (e.g. /dev/sdf) as such; the kernel may see /dev/nvme1n1 etc.
  cloud_init_mounts = [
    for k, v in var.data_volumes : {
      device_path = "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_${replace(aws_ebs_volume.data[k].id, "-", "")}"
      mount_path  = v.mount_path
      label       = replace(trimprefix(v.mount_path, "/"), "/", "-")
    }
    if v.mount_path != ""
  ]

  needs_cloud_init = var.cloud_init_user_rename != "" || length(local.cloud_init_mounts) > 0

  # null (not "") when there's nothing to render, so the legacy module call
  # (no rename, no mount_path set) produces exactly the same user_data value
  # (null) it has today — no diff on the live legacy instance.
  rendered_user_data = local.needs_cloud_init ? templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    user_rename = var.cloud_init_user_rename
    mounts      = local.cloud_init_mounts
  }) : null
}

resource "aws_volume_attachment" "data" {
  for_each    = var.data_volumes
  device_name = each.key
  volume_id   = aws_ebs_volume.data[each.key].id
  instance_id = aws_instance.this.id
}
