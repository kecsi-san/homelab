resource "aws_route53_zone" "this" {
  for_each = toset(var.domains)
  name     = each.key

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "mx" {
  for_each = toset(var.domains)

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = each.key
  type    = "MX"
  ttl     = 300
  records = ["10 ${var.mail_hostname}."]
}

resource "aws_route53_record" "spf" {
  for_each = toset(var.domains)

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = each.key
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 mx -all"]
}

resource "aws_route53_record" "dmarc" {
  for_each = toset(var.domains)

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = "_dmarc.${each.key}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=quarantine; rua=mailto:postmaster@${each.key}"]
}

locals {
  # Derive parent zone from mail_hostname FQDN (strips the first label: mail.example.com → example.com)
  mail_domain = join(".", slice(split(".", var.mail_hostname), 1, length(split(".", var.mail_hostname))))
}

resource "aws_route53_record" "mail" {
  zone_id = aws_route53_zone.this[local.mail_domain].zone_id
  name    = var.mail_hostname
  type    = "A"
  ttl     = 300
  records = [var.mail_public_ip]
}

# DKIM records — uncomment and fill in public keys after ec2-mail.yml generates them.
# Run: ansible-playbook playbooks/ec2-mail.yml -t dkim-dns  to print the keys.
#
# resource "aws_route53_record" "dkim" {
#   for_each = toset(var.domains)
#   zone_id  = aws_route53_zone.this[each.key].zone_id
#   name     = "mail._domainkey.${each.key}"
#   type     = "TXT"
#   ttl      = 300
#   records  = ["v=DKIM1; k=rsa; p=<public-key-from-ansible-output>"]
# }
