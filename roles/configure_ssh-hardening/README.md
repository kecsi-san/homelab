# configure_ssh-hardening

Codifies sshd connection/session hardening as an Ansible-managed drop-in, replacing a hand-applied `lynis`-generated config.

## Why

The live EC2 box has `/etc/ssh/sshd_config.d/lynis_hardening.conf` — created once by running `lynis`, never brought under Ansible management. It was flagged as a gap in `docs/howtos/ec2-rebuild-plan.md`'s audit (alongside `configure_duo-ssh`, which already handles the MFA-specific parts of sshd config separately).

## What it does

- Deploys `/etc/ssh/sshd_config.d/hardening.conf` with connection/session limits and forwarding restrictions (see Variables)
- Validates the full effective sshd config with `sshd -t` **before** reloading — if validation fails, the play stops and sshd is never reloaded (still running on the old, working config)
- Reloads (not restarts) sshd on change — a SIGHUP-based reload re-reads config for new connections only; already-established sessions are unaffected

## Intentionally dropped from the original lynis output

`UsePrivilegeSeparation SANDBOX` is **not** included — it's deprecated in modern OpenSSH and does nothing on Debian 13. Including it just produces a harmless `sshd -t` warning (`Deprecated option UsePrivilegeSeparation`), which is exactly what you'd see today running `sshd -t` against the live box's current drop-in.

## Variables

| Variable | Default | Directive |
|----------|---------|-----------|
| `sshd_hardening_banner` | `/etc/issue.net` | `Banner` |
| `sshd_hardening_allow_tcp_forwarding` | `false` | `AllowTcpForwarding` |
| `sshd_hardening_client_alive_count_max` | `2` | `ClientAliveCountMax` |
| `sshd_hardening_compression` | `false` | `Compression` |
| `sshd_hardening_log_level` | `VERBOSE` | `LogLevel` |
| `sshd_hardening_max_auth_tries` | `2` | `MaxAuthTries` |
| `sshd_hardening_max_sessions` | `2` | `MaxSessions` |
| `sshd_hardening_permit_root_login` | `false` | `PermitRootLogin` |
| `sshd_hardening_x11_forwarding` | `false` | `X11Forwarding` |
| `sshd_hardening_allow_agent_forwarding` | `false` | `AllowAgentForwarding` |
| `sshd_hardening_tcp_keepalive` | `false` | `TCPKeepAlive` |

## Manual rollback

```bash
sudo rm /etc/ssh/sshd_config.d/hardening.conf
sudo sshd -t && sudo systemctl reload ssh
```

## Rollout safety

Much lower risk than `configure_duo-ssh` (no authentication-method changes — just connection/session limits and forwarding toggles), but apply the same discipline:

1. Confirm `sshd -t` passed (the play would have failed otherwise).
2. Open a fresh SSH connection and confirm it still works before closing any existing session.

See [`setup_aws-ssm-agent`](../setup_aws-ssm-agent/README.md) for an out-of-band rescue path independent of sshd.

## Usage

```yaml
- name: Configure SSH hardening
  ansible.builtin.import_role:
    name: configure_ssh-hardening
  tags:
    - ssh
    - hardening
    - security
```
