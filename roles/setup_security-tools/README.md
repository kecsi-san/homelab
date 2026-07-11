# setup_security-tools

Installs security scanning and hardening utilities.

## What it does

### APT packages

| Package | Purpose |
|---------|---------|
| `fail2ban` | Brute-force protection — bans IPs after repeated auth failures |
| `rkhunter` | Rootkit scanner and system integrity checker |

### Cisofy apt repo

Adds the official [Cisofy](https://cisofy.com) apt repository and installs:

| Package | Purpose |
|---------|---------|
| `lynis` | Security auditing and hardening tool for Linux systems |

### Homebrew

| Package | Purpose |
|---------|---------|
| `trivy` | Vulnerability and misconfiguration scanner for containers, IaC, and filesystems |
| `hadolint` | Dockerfile linter — best-practice and security checks |

> `trivy` is also installed by `setup_iac-terraform` — the duplicate is intentional so this role is self-contained.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `security_apt_packages` | `[fail2ban, rkhunter]` | APT packages to install |

## Usage

```yaml
- name: Setup security tools
  ansible.builtin.import_role:
    name: setup_security-tools
  tags:
    - security
```

## Notes

- APT tasks and repo setup require `become: true` internally
- Homebrew (trivy, hadolint) runs as user (`become: false`)
- `lynis` can be run manually: `sudo lynis audit system`
- `rkhunter` initial database: `sudo rkhunter --update && sudo rkhunter --propupd`
