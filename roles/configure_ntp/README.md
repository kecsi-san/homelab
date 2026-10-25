# configure_ntp

Disables `systemd-timesyncd` and installs/configures `chrony` for time sync
(Debian 13 dropped the classic `ntpd` package). Prefers the MikroTik router
as primary time source (lowest LAN latency, always available), with
`pool.ntp.org` servers as fallback.

## What it does

- Stops and disables `systemd-timesyncd` (`failed_when: false`, not present
  on every image)
- Removes `ntpsec` when it is installed (see Notes), without `autoremove`
- Installs `chrony` via apt
- Templates `/etc/chrony/chrony.conf`, restarts chrony on change
- Ensures chrony is started and enabled

## Variables

| Variable | Default | Description |
|----------|---------|--------------|
| `ntp_primary_server` | `192.168.1.1` | Primary NTP source (MikroTik router), marked `prefer` in `chrony.conf` |
| `ntp_fallback_servers` | `0.pool.ntp.org`, `1.pool.ntp.org`, `2.pool.ntp.org` | Public fallback servers used when the router is unreachable |
| `ntp_remove_ntpsec` | `true` | Remove `ntpsec` before installing chrony. Set `false` to let apt resolve the conflict itself |

`chrony.conf` also hardcodes `makestep 1.0 3` (step the clock if offset > 1s
during the first 3 updates, slew-only after) and `rtcsync` (periodic
hardware RTC sync); neither is exposed as a variable.

## Usage

```yaml
- name: Configure NTP
  ansible.builtin.import_role:
    name: configure_ntp
  become: true
  tags:
    - ntp
```

Wired into `k8s-nodes.yml`, `fileservers.yml`, `ec2-core.yml`, and
`local-core.yml` (Linux only in the last case).

## Notes

- On the EC2 edge node the router isn't reachable, so `aws_all.yml` overrides
  `ntp_primary_server` with the VPC's Time Sync Service (`169.254.169.123`).
- `ntpsec` and `chrony` both provide `time-daemon` and conflict. Since Debian 12
  the `ntp` package is a stand-in for `ntpsec`, so a host upgraded in place from
  Debian 12 can already run `ntpsec` without anyone having chosen it; the live
  EC2 edge node did. The role removes it first. Fresh Debian 13 installs have
  neither, so the guard skips there. On a host you don't want touched, check it
  first: `ansible-playbook -i inventory/aws_hosts playbooks/ec2-core.yml --tags ntp --check --diff`.
- WSL2 boot-time clock drift is a separate, unrelated issue handled by a
  `chronyd -q` pre-correct step outside this role, not something this role's
  `chrony.conf` addresses on its own.
