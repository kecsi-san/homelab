# configure_sudo

Configures passwordless sudo for the admin user by creating a validated sudoers drop-in file.

## What it does

- Creates `/etc/sudoers.d/{{ sudo_user }}` with `NOPASSWD: ALL`
- Validates the file with `visudo -cf` before writing (safe; will not break sudo on syntax error)
- Idempotent via `lineinfile` with a regexp guard

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `sudo_user` | `{{ admin_user }}` | User to grant passwordless sudo |

## Usage

```yaml
- name: Configure sudo
  ansible.builtin.import_role:
    name: configure_sudo
  become: true
  tags:
    - sudo
    - prerequisites
    - developer
```

## Notes

- Must be run with `become: true`
- Run early (via `prerequisite.yml`) so subsequent playbook tasks don't prompt for a password
