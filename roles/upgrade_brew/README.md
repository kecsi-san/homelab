# upgrade_brew

Upgrades all Homebrew-managed packages and cleans up old versions.

Covers **Tier 2** of the tool management strategy. Companion to `debian_upgrade` (APT) and `upgrade_python-uv` (uv). See [Tool Management Philosophy](../../README.md#tool-management-philosophy).

## What it does

1. `brew update`: fetches latest formulae and cask definitions
2. `brew upgrade`: upgrades all installed packages to latest
3. `brew cleanup`: removes old versions (default: anything older than 1 day)

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `brew_bin` | `/home/linuxbrew/.linuxbrew/bin/brew` | Path to the brew binary |
| `brew_cleanup_max_age_days` | `1` | Max age in days before old versions are removed |

## Usage

```yaml
- name: Upgrade Homebrew packages
  ansible.builtin.import_role:
    name: upgrade_brew
  become: false
  tags:
    - upgrade
    - brew
```

## Notes

- `become: false`: Homebrew runs entirely in user space
- Safe to run regularly; equivalent to running `brew update && brew upgrade && HOMEBREW_CLEANUP_MAX_AGE_DAYS=1 brew cleanup` manually
