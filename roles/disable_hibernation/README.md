# disable_hibernation

Disables all forms of system sleep and hibernation via systemd; intended for always-on servers.

## What it does

1. Creates `/etc/systemd/sleep.conf.d/nosuspend.conf` disabling all sleep modes
2. Reloads systemd daemon if the config was changed
3. Masks the following systemd targets to prevent accidental activation:
   - `sleep.target`
   - `suspend.target`
   - `hibernate.target`
   - `hybrid-sleep.target`

## Usage

```yaml
- name: Disable hibernation
  ansible.builtin.import_role:
    name: disable_hibernation
  become: true
  tags:
    - hibernation
    - server
```

## Notes

- Requires `become: true`
- Intended for bare-metal servers and homelab nodes; not needed on desktops
- Masking targets survives reboots; the `nosuspend.conf` drop-in provides an additional layer
