# debian_upgrade

Performs a full APT package upgrade and cleans up stale packages.

## What it does

1. `apt update` (cache valid for 1 hour)
2. Upgrades all packages to latest
3. `apt autoclean`: removes obsolete cached packages
4. `apt autoremove --purge`: removes unused dependency packages and their config

## Usage

```yaml
- name: Upgrade Debian packages
  ansible.builtin.import_role:
    name: debian_upgrade
  become: true
  tags:
    - update
    - maintenance
```

Run standalone across all kube hosts:

```bash
ansible-playbook playbooks/upgrade.yml
```

## Notes

- Does not reboot after upgrade; trigger manually if kernel updates require it
- Safe to run regularly (weekly recommended)
- Covers **Tier 1** of the tool management strategy (system-level, APT-managed packages). See [Tool Management Philosophy](../../README.md#tool-management-philosophy).
