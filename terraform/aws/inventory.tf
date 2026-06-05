# Writes inventory/aws_hosts after every apply so Ansible always has the current EIP.
# This file is gitignored — it contains the live IP address.
resource "local_file" "ansible_inventory" {
  content         = "[aws]\n${aws_eip.ec2.public_ip} ansible_user=${var.admin_user}\n"
  filename        = "${path.root}/../../inventory/aws_hosts"
  file_permission = "0600"
}
