# configure_postfix-smarthost

Sends mail for selected recipient domains through an authenticated relay (Amazon SES by default)
and leaves every other message on direct delivery. Built for Microsoft's consumer domains
(Outlook.com, Hotmail, Live, MSN), which block parts of the AWS EC2 address range.

It changes only the relay settings, using `postconf -e`, so it is safe on the live EC2 mail server's
hand-built `main.cf` (`setup_email-server` would rewrite the whole file). Existing `transport_maps`
entries stay in place after the new map.

## What it does

- Writes three maps under `/etc/postfix/`: `transport_smarthost` (domain to relay), `sasl_passwd_smarthost`
  (mode 0600) and `tls_policy_smarthost`, and builds their hash files with `postmap`.
- Puts those maps first in `transport_maps`, `smtp_sasl_password_maps` and `smtp_tls_policy_maps`.
- Sets `smtp_sasl_auth_enable`, `smtp_sasl_security_options` and `smtp_sasl_tls_security_options`.
- Runs `postfix check`, then reloads Postfix when something changed.

There are no handlers: the postmap and reload steps are plain tasks, because a handler did not fire
on the live EC2 node (see `TODO.md`).

## Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `postfix_smarthost_enabled` | `false` | The role does nothing unless a play sets it to `true` |
| `postfix_smarthost_relay_host` | `email-smtp.eu-west-1.amazonaws.com` | Relay host name |
| `postfix_smarthost_relay_port` | `587` | Relay port (STARTTLS) |
| `postfix_smarthost_username` | *(none)* | SMTP user name; the role fails early when empty. Read from Vault in `inventory/group_vars/aws_all.yml` |
| `postfix_smarthost_password` | *(none)* | SMTP password; same |
| `postfix_smarthost_domains` | contents of `files/microsoft-consumer-domains.txt` | Recipient domains that use the relay |
| `postfix_smarthost_tls_level` | `verify` | `verify` checks the certificate chain and host name, `encrypt` only requires TLS |
| `postfix_smarthost_dir` | `/etc/postfix` | Where the map files go |

## Domain list

`files/microsoft-consumer-domains.txt` is generated from public DNS by `scripts/ms-consumer-domains.sh`:
a domain is included when its lowest-preference MX is in `*.olc.protection.outlook.com` or
`*.mx.microsoft`. Regenerate it now and then (`scripts/ms-consumer-domains.sh > ...`); Microsoft adds
country domains rarely.

## Usage

```bash
ansible-playbook -i inventory/aws_hosts playbooks/ec2-smarthost.yml --check --diff
ansible-playbook -i inventory/aws_hosts playbooks/ec2-smarthost.yml
```

The AWS side (SES identities, the IAM user, DNS records) and the credentials are described in
`docs/howtos/ses-relay.md`. Confirm with the owner before connecting to the production host.
