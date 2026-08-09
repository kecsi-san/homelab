# configure_ntp

Disables `systemd-timesyncd` and installs/configures `chrony` for time sync
(Debian 13 dropped the classic `ntpd` package). Prefers the MikroTik router
as primary time source (lowest LAN latency, always available), with
`pool.ntp.org` servers as fallback.

## What it does

- Stops and disables `systemd-timesyncd` (`failed_when: false`, not present
  on every image)
- Installs `chrony` via apt
- Templates `/etc/chrony/chrony.conf`, restarts chrony on change
- Ensures chrony is started and enabled

## Variables

| Variable | Default | Description |
|----------|---------|--------------|
| `ntp_primary_server` | `192.168.1.1` | Primary NTP source (MikroTik router), marked `prefer` in `chrony.conf` |
| `ntp_fallback_servers` | `0.pool.ntp.org`, `1.pool.ntp.org`, `2.pool.ntp.org` | Public fallback servers used when the router is unreachable |

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

- On the EC2 edge node, the router isn't reachable, so `ntp_primary_server`
  would need overriding per-host if router-first behavior there is ever
  undesirable; currently it just falls through to the pool servers when the
  primary can't be reached, same as any other unreachable-primary case.
- WSL2 boot-time clock drift is a separate, unrelated issue handled by a
  `chronyd -q` pre-correct step outside this role, not something this role's
  `chrony.conf` addresses on its own.
