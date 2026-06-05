resource "aws_eip" "ec2" {
  domain = "vpc"

  tags = {
    Name = "homelab-edge"
  }
}

resource "aws_eip_association" "ec2" {
  instance_id   = aws_instance.ec2.id
  allocation_id = aws_eip.ec2.id
}
