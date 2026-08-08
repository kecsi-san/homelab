# configure_duo-ssh

Migrates SSH MFA (`duo-unix`) from `ForceCommand /usr/sbin/login_duo` to PAM-based `pam_duo.so`, scoped to sshd only.

## Why

`ForceCommand`-based Duo fires on every SSH session channel, regardless of SSH ControlMaster/ControlPersist connection reuse; so tools like Ansible that open many sessions against the same host trigger a Duo push per task. PAM-based Duo runs during the SSH *authentication* phase instead: once a connection authenticates (publickey + Duo), ControlPersist lets subsequent sessions over that same connection skip re-authentication entirely.

## What it does

- Deploys `/etc/duo/pam_duo.conf` with `ikey`/`skey`/`host`/`failmode` (`duo_ikey`, `duo_skey`, `duo_api_host`: from `secrets.yml`)
- Replaces the `ForceCommand` line in `/etc/ssh/sshd_config.d/duo_2fa.conf` with:
  ```
  KbdInteractiveAuthentication yes
  AuthenticationMethods publickey,keyboard-interactive
  ```
- Edits `/etc/pam.d/sshd` only: removes `@include common-auth` and adds `auth required {{ duo_pam_module_path }}` in its place
- Validates the full effective sshd config with `sshd -t` **before** reloading; if validation fails, the play stops and sshd is never reloaded (still running on the old, working config)
- Reloads (not restarts) sshd on change; a SIGHUP-based reload re-reads config for new connections only; already-established sessions (including the one applying this change, if run interactively) are unaffected

## Why Duo stays SSH-only

Only `/etc/pam.d/sshd` is touched; never `/etc/pam.d/common-auth`, which `sudo`, `su`, and console/GUI logins include. Those keep using plain `pam_unix.so` with no Duo prompt.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `duo_pam_failmode` | `safe` | `safe` allows login if Duo's config/API is unreachable; `secure` denies it (higher lockout risk) |
| `duo_ssh_authentication_methods` | `publickey,keyboard-interactive` | Both factors required, in this order |
| `duo_pam_autopush` | `true` | Automatically sends a Duo Push instead of prompting for passcode/option selection on every login |
| `duo_pam_module_path` | `/lib64/security/pam_duo.so` | Full path to the PAM module. Debian 13's `duo-unix` package installs it under `/lib64/security/`, not the multiarch `/lib/x86_64-linux-gnu/security/` path libpam searches by default for a bare module name; referencing it by bare name (`pam_duo.so`) fails with `PAM: Module is unknown`. Verify with `dpkg -L duo-unix \| grep pam_duo.so` if targeting a different distro/version. |

Requires `duo_ikey`, `duo_skey`, `duo_api_host` in `secrets.yml` (copy from the host's existing `/etc/duo/login_duo.conf`: same Duo application).

## Required: Ansible must be allowed to use keyboard-interactive

Ansible's ssh connection plugin hardcodes `-o KbdInteractiveAuthentication=no` and drops `keyboard-interactive` from `PreferredAuthentications` whenever no `ansible_password` is set; this silently breaks against any host requiring keyboard-interactive as a second factor (`Permission denied (keyboard-interactive)` right after a successful partial publickey auth). Overriding this via `ansible_ssh_common_args`/`ansible_ssh_extra_args` does **not** work; ssh honors the first occurrence of a repeated `-o` key, and those two land *after* Ansible's own hardcoded flags. Only `ansible_ssh_args` is inserted early enough to win, and it replaces the default rather than appending, so Ansible's own default must be repeated too. See `inventory/group_vars/aws_all.yml`:

```yaml
ansible_ssh_args: >-
  -C -o ControlMaster=auto -o ControlPersist=60s
  -o PreferredAuthentications=publickey,keyboard-interactive
  -o KbdInteractiveAuthentication=yes
```

With this set, Ansible completes the Duo challenge itself on the first connection of a run (no PTY needed; Duo's `autopush` flow works fine non-interactively) and reuses that connection via its own `ControlPersist` for the rest of the run; no need to manually pre-authenticate a `ControlMaster` session first.

## Manual rollback

If something goes wrong after applying, revert by hand (using an already-open session or AWS SSM):

1. In `/etc/pam.d/sshd`: remove the `auth required pam_duo.so` line, restore `@include common-auth`.
2. Restore `ForceCommand /usr/sbin/login_duo` in `/etc/ssh/sshd_config.d/duo_2fa.conf` (remove `KbdInteractiveAuthentication`/`AuthenticationMethods` lines).
3. `sshd -t && systemctl reload ssh`

## Rollout safety

Do not rely on this role alone to prove SSH still works. After running it:

1. Confirm `sshd -t` passed (the play would have failed otherwise).
2. Open a **brand-new** SSH connection (not a multiplexed/reused one) and confirm publickey → Duo push → login succeeds, before closing any existing session.
3. Confirm `sudo -n true` still works with no Duo prompt (proves scoping to SSH only).

See [`setup_aws-ssm-agent`](../setup_aws-ssm-agent/README.md) for an out-of-band rescue path independent of sshd.

## Usage

```yaml
- name: Configure Duo SSH MFA (PAM-based)
  ansible.builtin.import_role:
    name: configure_duo-ssh
  become: true
  tags:
    - ssh
    - duo
    - security
```
