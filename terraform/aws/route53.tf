# Zones looked up by domain name — no zone IDs in code.
# Import existing zones before first apply:
#   terraform import 'aws_route53_zone.zones["kecskemethy.com"]' <zone-id>
#   terraform import 'aws_route53_zone.zones["kecskemethy.net"]' <zone-id>

locals {
  # Domains that have Route53 hosted zones in this account.
  # kecskemethy.org is managed via Cloudflare — add here if/when moved to Route53.
  route53_domains = ["kecskemethy.com", "kecskemethy.net"]

  # mail hostname — primary SMTP/IMAP endpoint, used in MX + TLS cert
  mail_hostname = "mail.kecskemethy.com"
}

resource "aws_route53_zone" "zones" {
  for_each = toset(local.route53_domains)
  name     = each.key

  lifecycle {
    prevent_destroy = true
  }
}

# MX records — all email_domains point to the single mail server
resource "aws_route53_record" "mx" {
  for_each = toset(local.route53_domains)

  zone_id = aws_route53_zone.zones[each.key].zone_id
  name    = each.key
  type    = "MX"
  ttl     = 300

  records = ["10 ${local.mail_hostname}."]
}

# SPF records
resource "aws_route53_record" "spf" {
  for_each = toset(local.route53_domains)

  zone_id = aws_route53_zone.zones[each.key].zone_id
  name    = each.key
  type    = "TXT"
  ttl     = 300

  records = ["v=spf1 mx -all"]
}

# DMARC records
resource "aws_route53_record" "dmarc" {
  for_each = toset(local.route53_domains)

  zone_id = aws_route53_zone.zones[each.key].zone_id
  name    = "_dmarc.${each.key}"
  type    = "TXT"
  ttl     = 300

  records = ["v=DMARC1; p=quarantine; rua=mailto:postmaster@${each.key}"]
}

# DKIM records — populated by Ansible after opendkim generates keys.
# Run: ansible-playbook playbooks/ec2-mail.yml -t dkim-dns
# to print the public key, then add it here as a TXT record.
#
# resource "aws_route53_record" "dkim" {
#   for_each = toset(local.route53_domains)
#   zone_id  = aws_route53_zone.zones[each.key].zone_id
#   name     = "mail._domainkey.${each.key}"
#   type     = "TXT"
#   ttl      = 300
#   records  = ["v=DKIM1; k=rsa; p=<public-key-from-ansible-output>"]
# }

# mail A record — points to the EIP
resource "aws_route53_record" "mail" {
  zone_id = aws_route53_zone.zones["kecskemethy.com"].zone_id
  name    = local.mail_hostname
  type    = "A"
  ttl     = 300
  records = [aws_eip.ec2.public_ip]
}
