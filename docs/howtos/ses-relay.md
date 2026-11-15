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
| SES identities, DKIM, IAM user | `terraform/aws/ses.tf` | One SES identity per sender domain with Easy DKIM, plus an IAM user that may only send as those domains |
| Recipient domain list | `roles/configure_postfix-smarthost/files/microsoft-consumer-domains.txt` | 68 domains, generated from public DNS by `scripts/ms-consumer-domains.sh` |
| Postfix change | `roles/configure_postfix-smarthost`, `playbooks/ec2-smarthost.yml` | A transport map sends those domains to the SES SMTP endpoint with authentication |
| Credentials | Vault `ec2/ses-relay` (`smtp_username`, `smtp_password`) | Read by Ansible from `inventory/group_vars/aws_all.yml` |

The role changes only the relay settings through `postconf -e`. It does not use `setup_email-server`,
which would rewrite the live `main.cf`.

DMARC stays satisfied: Rspamd signs the message with the domain's own DKIM key before Postfix hands it to SES,
and SES adds a second signature for the same domain. SPF does not align through SES (the bounce address
is an `amazonses.com` one), so DMARC passes on DKIM alone.

## Steps

### 1. Create the SES identities (Terraform)

Set the sender domains in `terraform/aws/terraform.tfvars` (gitignored). Every domain the mail server sends
for needs an entry, because SES rejects a From domain it has not verified.

```hcl
ses_sender_domains = ["example.com", "example.net", "example.org"]
```

```bash
cd terraform/aws
terraform plan
terraform apply
```

Domains that are also in `route53_domains` get their DKIM records from Terraform. For the others,
`terraform output ses_dkim_manual_records` lists the three CNAME records per domain.

### 2. Add the DKIM records for domains outside Route53

Add the three CNAME records per domain at that domain's DNS host (for the two Hungarian domains that is
the registrar's own DNS panel, outside Terraform). SES marks each identity as verified once the records
resolve, usually within minutes to an hour.

```bash
aws sesv2 get-email-identity --email-identity example.com \
  --query '{verified: VerifiedForSendingStatus, dkim: DkimAttributes.Status}'
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
the dry run only reports, the real run changes seven things, and a second run changes nothing. The legacy
map stays in the list after the new one.

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
| `Server certificate not verified` | `smtp_tls_CAfile` or `smtp_tls_CApath` is missing on the host; set `postfix_smarthost_tls_level: encrypt` only as a stopgap |
| Microsoft still rejects the message | The message did not go through the relay; check the transport map lookup above |

To switch the relay off, remove the first entry (`hash:/etc/postfix/transport_smarthost`) from `transport_maps`
with `postconf -e`, then `postfix reload`. Queued mail is then delivered directly.

## Notes

- **Cost:** SES charges about $0.10 per 1,000 messages, so this is a few cents a month for personal mail.
- **Rebuilt instance:** it only needs the same playbook run and the same Vault secret. The relay does not depend on the instance's IP.
- **Domain list:** regenerate it now and then with `scripts/ms-consumer-domains.sh`. A domain is included when its lowest-preference MX is in `*.olc.protection.outlook.com` or `*.mx.microsoft`.
