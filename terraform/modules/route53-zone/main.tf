resource "aws_route53_zone" "this" {
  for_each = toset(var.domains)
  name     = each.key

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [comment]
  }
}

resource "aws_route53_record" "apex_a" {
  for_each = toset(var.domains)

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = each.key
  type    = "A"
  ttl     = 86400
  records = [var.mail_public_ip]
}

resource "aws_route53_record" "apex_aaaa" {
  for_each = toset(var.domains)

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = each.key
  type    = "AAAA"
  ttl     = 86400
  records = [var.mail_ipv6]
}

resource "aws_route53_record" "mx" {
  for_each = toset(var.domains)

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = each.key
  type    = "MX"
  ttl     = 86400
  records = ["10 mail.${each.key}"]
}

resource "aws_route53_record" "spf" {
  for_each = toset(var.domains)

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = each.key
  type    = "TXT"
  ttl     = 86400
  records = ["v=spf1 -all"]
}

resource "aws_route53_record" "dmarc" {
  for_each = toset(var.domains)

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = "_dmarc.${each.key}"
  type    = "TXT"
  ttl     = 86400
  records = ["v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s;"]
}

resource "aws_route53_record" "mail_a" {
  for_each = toset(var.domains)

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = "mail.${each.key}"
  type    = "A"
  ttl     = 86400
  records = [var.mail_public_ip]
}

resource "aws_route53_record" "mail_aaaa" {
  for_each = toset(var.domains)

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = "mail.${each.key}"
  type    = "AAAA"
  ttl     = 86400
  records = [var.mail_ipv6]
}

# Wildcard DKIM — created only for domains with a key in var.dkim_keys.
# Root module computes this from Vault (ec2/dkim-public/<domain>, written by
# roles/setup_email-server) rather than a literal tfvars value — see
# terraform/aws/main.tf and docs/howtos/vault-secrets-architecture.md.
resource "aws_route53_record" "dkim" {
  for_each = var.dkim_keys

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = "*._domainkey.${each.key}"
  type    = "TXT"
  ttl     = 86400
  records = [each.value]
}
