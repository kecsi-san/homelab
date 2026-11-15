# Relay Microsoft consumer mail through Amazon SES

Outlook.com, Hotmail, Live and MSN block parts of the AWS EC2 address range. On 2026-11-15 mail from the
EC2 mail server to those domains bounced with `550 5.7.1 ... block list (S3150)`. Microsoft lifted the
block for the server's /24 the same day, but only conditionally (low daily limits, removed again after
user complaints). Sending those recipients through Amazon SES is the lasting fix: SES addresses carry
their own reputation, and a rebuilt instance with a new Elastic IP is not affected.

Only the Microsoft consumer domains use the relay. Everything else is still delivered directly.

## How it fits together

| Part | Where | What it does |
|------|-------|--------------|
| SES identities, DKIM, MAIL FROM, IAM user | `terraform/aws/ses.tf` | One SES identity per sender domain with Easy DKIM and a custom MAIL FROM subdomain (`ses.<domain>`), plus an IAM user that may only send as those domains |
| Recipient domain list | `roles/configure_postfix-smarthost/files/microsoft-consumer-domains.txt` | 68 domains, generated from public DNS by `scripts/ms-consumer-domains.sh` |
| Postfix change | `roles/configure_postfix-smarthost`, `playbooks/ec2-smarthost.yml` | A transport map sends those domains to the SES SMTP endpoint with authentication |
| Credentials | Vault `ec2/ses-relay` (`smtp_username`, `smtp_password`) | Read by Ansible from `inventory/group_vars/aws_all.yml` |

The role changes only the relay settings through `postconf -e`. It does not use `setup_email-server`,
which would rewrite the live `main.cf`.

DMARC stays satisfied: Rspamd signs the message with the domain's own DKIM key before Postfix hands it to SES,
and SES adds a second signature for the same domain. SES sends with a bounce address under `ses.<domain>`
(the custom MAIL FROM domain), so receivers see an envelope sender in your own domain and SPF passes for it.
The domains publish DMARC with strict SPF alignment, which a subdomain does not satisfy, so DMARC passes on
DKIM; that is enough.

## Steps

### 1. Create the SES identities (Terraform)

List the base sender domains in `terraform/aws/terraform.tfvars` (gitignored). The `ses.<domain>` MAIL FROM
subdomain is derived from each one. SES rejects mail whose From domain it has not verified, so every domain
the mail server sends for needs an entry.

```hcl
ses_sender_domains = ["example.com", "example.net"]
```

Apply only the SES resources. A plain `terraform apply` in this directory would also create the new edge
instance from the Phase 6 rebuild, which is waiting on its own go/no-go.

```bash
cd terraform/aws
terraform plan -target=aws_sesv2_email_identity.sender \
  -target=aws_sesv2_email_identity_mail_from_attributes.sender \
  -target=aws_iam_user.ses_relay -target=aws_iam_user_policy.ses_relay -out=ses.tfplan
terraform apply ses.tfplan
```

The plan should show only SES and IAM resources (identities, MAIL FROM settings, the IAM user and its policy)
and no changes or destroys.

**Adding domains later:** add them to `ses_sender_domains` and apply the same way. Do the DNS records and wait
for verification before running the Postfix playbook, or add every sender domain first. Postfix chooses the relay
by recipient domain, not by sender, so mail from a domain that SES has not verified would be rejected by SES
and bounced to the sender.

### 2. Add the DNS records for domains outside Route53

Add the five records per domain at that domain's DNS host: the registrar's own DNS panel for the two Hungarian
domains, and Cloudflare for the `.org` domain, all outside Terraform. At Cloudflare set the three CNAME records to
**DNS only** (grey cloud); a proxied CNAME breaks DKIM. SES marks each identity as verified once the DKIM records
resolve, usually within minutes to an hour. Until the MX and TXT records for the MAIL FROM subdomain resolve,
SES falls back to its own `amazonses.com` bounce address, so mail keeps flowing.

```bash
aws sesv2 get-email-identity --email-identity example.com \
  --query '{verified: VerifiedForSendingStatus, dkim: DkimAttributes.Status, mailFrom: MailFromAttributes.MailFromDomainStatus}'
```

### 3. Request SES production access

A new SES account starts in the sandbox: mail goes only to verified addresses and the daily quota is tiny.
In the SES console open **Account dashboard** and choose **Request production access** for the same region
as the server (`eu-west-1`). Describe the use as low-volume personal and family mail from a self-hosted
server, with bounces and complaints handled. Approval usually takes about a day. Until then, relayed mail to
unverified Microsoft addresses is rejected with `554 Message rejected: Email address is not verified`.

### 4. Create the SMTP credentials and store them in Vault

The Terraform code creates the IAM user but no access key, so the secret never enters the state file.

```bash
aws iam create-access-key --user-name postfix-ses-relay
scripts/ses-smtp-password.py eu-west-1      # prompts for the secret access key, prints the SMTP password
vault kv put ec2/ses-relay smtp_username=<AccessKeyId> smtp_password=<printed password>
```

The SMTP user name is the access key id unchanged. The password is derived from the secret key by the script,
because SES does not accept the raw IAM secret. Clear the terminal scrollback afterwards.

### 5. Apply the Postfix change

This changes live mail routing on the production server, so confirm before connecting. Look first, then apply:

```bash
ansible-playbook -i inventory/aws_hosts playbooks/ec2-smarthost.yml --check --diff
ansible-playbook -i inventory/aws_hosts playbooks/ec2-smarthost.yml
```

The role was tested against a Debian 13 container with Postfix 3.10 and a pre-existing `transport_maps`:
the dry run only reports, the real run changes eight things, and a second run changes nothing. The legacy
map stays in the list after the new one. The live server has no CA store configured (`smtp_tls_CAfile` and
`smtp_tls_CApath` are empty), so the role sets `smtp_tls_CAfile` to the system bundle when none exists;
without it Postfix could not verify the SES certificate. The global `smtp_sasl_security_options` is not touched.

### 6. Verify

On the server:

```bash
postmap -q hotmail.com hash:/etc/postfix/transport_smarthost     # smtp:[email-smtp.eu-west-1.amazonaws.com]:587
postconf transport_maps smtp_sasl_password_maps smtp_tls_policy_maps
```

Then send a short mail to a Microsoft address you control and watch the log:

```bash
grep 'relay=email-smtp' /var/log/mail.log | tail
```

`status=sent` through `email-smtp.eu-west-1.amazonaws.com` means it worked. In the received message, the headers show
`amazonses.com` and DKIM `pass` for your domain.

## When something goes wrong

| Symptom | Likely cause |
|---------|--------------|
| `status=deferred ... 535 Authentication Credentials Invalid` | Wrong SMTP user name or password in Vault. Mail stays queued, nothing is lost. |
| `554 ... Email address is not verified` | The From domain is not an SES identity, or SES is still in the sandbox |
| `Server certificate not verified` | No CA bundle available (the role sets `smtp_tls_CAfile` when none is configured, and fails if `/etc/ssl/certs/ca-certificates.crt` is missing); install `ca-certificates`, and use `postfix_smarthost_tls_level: encrypt` only as a stopgap |
| Microsoft still rejects the message | The message did not go through the relay; check the transport map lookup above |

To switch the relay off, remove the first entry (`hash:/etc/postfix/transport_smarthost`) from `transport_maps`
with `postconf -e`, then `postfix reload`. Queued mail is then delivered directly.

## Notes

- **Cost:** SES charges about $0.10 per 1,000 messages, so this is a few cents a month for personal mail.
- **Rebuilt instance:** it only needs the same playbook run and the same Vault secret. The relay does not depend on the instance's IP.
- **Domain list:** regenerate it now and then with `scripts/ms-consumer-domains.sh`. A domain is included when its lowest-preference MX is in `*.olc.protection.outlook.com` or `*.mx.microsoft`.
