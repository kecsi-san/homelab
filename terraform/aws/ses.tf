# Amazon SES as an outbound relay for Microsoft consumer recipients (Outlook.com, Hotmail, Live,
# MSN), which block parts of the EC2 address range. Postfix on the mail server relays only those
# domains through SES; everything else is still delivered directly. Postfix side:
# roles/configure_postfix-smarthost. Runbook: docs/howtos/ses-relay.md.

# One SES identity per sender domain. SES refuses mail whose From domain is not verified, so every
# domain the mail server sends for needs an entry. Easy DKIM (the three CNAME records below)
# is also what verifies the domain.
resource "aws_sesv2_email_identity" "sender" {
  for_each       = toset(var.ses_sender_domains)
  email_identity = each.key

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }
}

locals {
  ses_dkim_tokens = {
    for domain, identity in aws_sesv2_email_identity.sender :
    domain => identity.dkim_signing_attributes[0].tokens
  }

  # Domains with a Route53 hosted zone get their DKIM records from Terraform; the others
  # (their DNS is elsewhere) are listed in the ses_manual_dns_records output to add by hand.
  ses_route53_domains = [for d in var.ses_sender_domains : d if contains(var.route53_domains, d)]
  ses_manual_domains  = [for d in var.ses_sender_domains : d if !contains(var.route53_domains, d)]

  ses_dkim_route53_records = {
    for pair in flatten([
      for d in local.ses_route53_domains : [
        for i in range(3) : { key = "${d}/${i}", domain = d, index = i }
      ]
    ]) : pair.key => pair
  }
}

resource "aws_route53_record" "ses_dkim" {
  for_each = local.ses_dkim_route53_records

  zone_id = module.route53.zone_ids[each.value.domain]
  name    = "${local.ses_dkim_tokens[each.value.domain][each.value.index]}._domainkey.${each.value.domain}"
  type    = "CNAME"
  ttl     = 1800
  records = ["${local.ses_dkim_tokens[each.value.domain][each.value.index]}.dkim.amazonses.com"]
}

# Custom MAIL FROM: SES sends with a bounce address under ses.<domain> instead of amazonses.com, so
# the envelope sender is the sender's own domain and SPF passes for it. It needs an MX record (SES
# receives bounces there) and an SPF TXT record on the subdomain. USE_DEFAULT_VALUE keeps mail flowing
# with the amazonses.com address until those records resolve.
resource "aws_sesv2_email_identity_mail_from_attributes" "sender" {
  for_each = aws_sesv2_email_identity.sender

  email_identity         = each.value.email_identity
  mail_from_domain       = "${var.ses_mail_from_subdomain}.${each.key}"
  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
}

resource "aws_route53_record" "ses_mail_from_mx" {
  for_each = toset(local.ses_route53_domains)

  zone_id = module.route53.zone_ids[each.key]
  name    = "${var.ses_mail_from_subdomain}.${each.key}"
  type    = "MX"
  ttl     = 1800
  records = ["10 feedback-smtp.${var.aws_region}.amazonses.com"]
}

resource "aws_route53_record" "ses_mail_from_spf" {
  for_each = toset(local.ses_route53_domains)

  zone_id = module.route53.zone_ids[each.key]
  name    = "${var.ses_mail_from_subdomain}.${each.key}"
  type    = "TXT"
  ttl     = 1800
  records = ["v=spf1 include:amazonses.com ~all"]
}

# The relay's SMTP identity. The IAM user may only send mail as the verified domains above.
# No access key is created here on purpose: a key created by Terraform would put its secret into
# the state file. Create it by hand and keep it in Vault, see docs/howtos/ses-relay.md.
resource "aws_iam_user" "ses_relay" {
  count = length(var.ses_sender_domains) > 0 ? 1 : 0

  name = var.ses_relay_iam_user_name
  path = "/service/"
}

data "aws_iam_policy_document" "ses_relay" {
  count = length(var.ses_sender_domains) > 0 ? 1 : 0

  statement {
    sid       = "SendAsVerifiedDomains"
    effect    = "Allow"
    actions   = ["ses:SendRawEmail"]
    resources = [for identity in aws_sesv2_email_identity.sender : identity.arn]
  }
}

resource "aws_iam_user_policy" "ses_relay" {
  count = length(var.ses_sender_domains) > 0 ? 1 : 0

  name   = "send-as-verified-domains"
  user   = aws_iam_user.ses_relay[0].name
  policy = data.aws_iam_policy_document.ses_relay[0].json
}
