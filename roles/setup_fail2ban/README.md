# setup_fail2ban

Installs fail2ban and writes one drop-in (`/etc/fail2ban/jail.d/homelab.local`) from variables: defaults, ignore list, and a set of jails.

## What it does

- Installs `fail2ban`, `python3-systemd` (journald backend) and `iptables`.
- Writes the drop-in with `ignoreip`, ban and find times, retries, backend, ban action and the jails you list.
- Runs `fail2ban-client --test` before restarting, so a bad file stops the play instead of leaving the service down.
- Enables and starts the service.

It manages no firewall rules. Bans use `iptables-multiport` by default, which fits `setup_firewall` (fail2ban adds its own `f2b-*` chains; the homelab chain is untouched).

## Why `ignoreip` matters

Bans are stored and restored after a reboot. A host that bans your own address, or a server of yours, can lock you out for the whole ban time. Always list your servers and admin addresses; the role keeps only localhost by default.

```yaml
fail2ban_ignoreip: "{{ ['127.0.0.1/8', '::1'] + firewall_trusted_sources }}"
```

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `fail2ban_enabled` | `false` | Playbooks run the role only when true |
| `fail2ban_ignoreip` | localhost | Addresses and CIDRs never banned |
| `fail2ban_bantime` | `1h` | Ban duration |
| `fail2ban_findtime` | `10m` | Window in which failures are counted |
| `fail2ban_maxretry` | `5` | Failures before a ban (jails can override) |
| `fail2ban_bantime_increment` | `false` | Longer bans for repeat offenders |
| `fail2ban_bantime_maxtime` | `1w` | Cap when increment is on |
| `fail2ban_banaction` | `iptables-multiport` | Ban action; the all-ports variant is derived from it |
| `fail2ban_backend` | `systemd` | Log backend |
| `fail2ban_jails` | `sshd` | Jail name to options, written verbatim under `[name]` |
| `fail2ban_apt_packages` | fail2ban, python3-systemd, iptables | Packages |

## Example: a mail server

```yaml
fail2ban_enabled: true
fail2ban_bantime: 1d
fail2ban_bantime_increment: true
fail2ban_jails:
  sshd:
    enabled: true
    maxretry: 3
  postfix:
    enabled: true
    mode: aggressive
  dovecot:
    enabled: true
    maxretry: 5
  postfix-sasl:
    enabled: true
```

Filters ship with the package. Check the names with `fail2ban-client -d` on the host if a jail refuses to start.

## Relation to `setup_security-tools`

That role can also install the `fail2ban` package. Installing it from there and configuring it here is fine; the package is installed once.

## Verify

```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd
sudo fail2ban-client get sshd ignoreip
```

Unban an address: `sudo fail2ban-client unban <address>`.

Dry run before applying: `ansible-playbook -i <inventory> playbooks/ec2-core.yml --tags fail2ban --check --diff`.
