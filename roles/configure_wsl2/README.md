# configure_wsl2

Deploys the full `/etc/wsl.conf` file. Migrated from the old `../dotfiles`
`bin/WSL2_setup_scripts/` (see homelab `TODO.md` "Dotfiles migration"); that directory's actual remaining gap (getting systemd running under WSL2)
turned out to be far simpler than the scripts there assumed: modern WSL2
just needs `systemd = true` in `[boot]`, no external script
(`diddledani/one-script-wsl2-systemd`) or sudoers drop-in needed anymore.
Rather than add just that one setting, this role codifies the *entire*
already-live `/etc/wsl.conf` on this workstation, not just the systemd bit.

The other 3 scripts that directory contained are already fully superseded
and were never migrated: `00-WSL2-install.txt` (manual pre-Ansible
PowerShell, not automatable), `01-install_docker_in_WSL2.sh` (→
`setup_apt_repos`'s `docker` tag), `03-install_k3s_wsl2.sh` (→ `setup_k3s`,
and was pinned to an obsolete k3s/kubectl version anyway).

## What it does

Templates `/etc/wsl.conf` from `templates/wsl.conf.j2`, covering
`[automount]`, `[network]`, `[interop]`, `[user]`, and `[boot]`: only on
WSL2 (detected via `'wsl2' in ansible_kernel`, e.g.
`6.18.33.2-microsoft-standard-WSL2`); a no-op everywhere else, safe to
import unconditionally.

Notifies a handler reminding you that `/etc/wsl.conf` changes only take
effect after a **full WSL2 restart**: `wsl --shutdown` from PowerShell/
cmd.exe on the **Windows** side, not something achievable from within WSL2
itself, then reopen your terminal.

Also appends `export BROWSER=/mnt/c/Windows/explorer.exe` to `~/.bashrc`
via an idempotent `blockinfile` block (same symlink-aware pattern as
`configure_fzf`/`configure_oh-my-posh`); also WSL2-gated. Most CLI tools
that need to open a browser (`gh auth login`, `aws sso login`, `az login`,
Python's `webbrowser` module, etc.) check `$BROWSER` first;
`explorer.exe` hands the URL to Windows, which opens it in your default
Windows browser, instead of failing to launch one inside WSL2. Requires
`[interop] enabled = true` in `wsl.conf` (see template below) so WSL2 can
invoke Windows executables.

## Variables

| Variable | Source | Description |
|----------|--------|--------------|
| `admin_user` | vaulted in `secrets.yml`/`local.yml` | `[user] default` |

`[network] hostname` uses `ansible_hostname` directly (no variable needed).

## Usage

```yaml
- name: Configure WSL2
  ansible.builtin.import_role:
    name: configure_wsl2
  tags:
    - wsl2
```

## Notes

- `become: true` only on the actual file-write task (system file under
  `/etc`), not the whole role; matches this repo's `become: false` at
  play level / `become: true` per-task-that-needs-it convention.
- `[boot] command = chronyd -q` pre-corrects the clock before systemd
  starts. The WSL2 VM's clock drifts while the Windows host sleeps
  (consistently 28-37s per boot, observed across multiple days in
  `journalctl`), and `chrony.service` (from `configure_ntp`) normally
  takes 30-60s to detect and step it; long past `initTimeout`, which
  produces a cosmetic (non-fatal) `wsl: Failed to start the systemd user
  session` warning. `chronyd -q` reads the same `/etc/chrony/chrony.conf`
  and does an immediate one-shot step, then exits; `chrony.service`
  still starts normally afterward for ongoing sync. This only works if
  the LAN is reachable that early in boot (true on this workstation;   the router is always up); if the network isn't ready that early on
  some other host, this would silently do nothing and `initTimeout`
  would need bumping instead.
- `[automount] options` hardcodes `uid=1000,gid=1000`: correct only if
  your primary WSL2 user is UID/GID 1000 (the default for the first user
  created). Not templated since it's been stable across this workstation's
  lifetime; revisit if that ever changes.
