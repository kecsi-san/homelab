# configure_bash-aliases

Deploys `~/.bash_aliases` (sourced automatically by the default `.bashrc`,
already present on this workstation — no extra wiring needed). Migrated
from the old `../dotfiles` `.bash_aliases` (see homelab `TODO.md`
"Dotfiles migration").

## What it does

- Installs `eza` via Homebrew (successor to the unmaintained `exa` the
  original aliases used)
- Installs `libnotify-bin` (Linux only) so `notify-send`, used by the
  `alert` alias, actually works
- Templates `~/.bash_aliases` from `templates/bash_aliases.j2`

## Aliases deployed

| Alias | What it does |
|-------|--------------|
| `ls`, `ll`, `l`, `la` | `eza`-based directory listings |
| `alert` | Desktop notification for the last command — handy prefixed onto a long-running command, e.g. `sleep 10; alert` |
| `kx [context]` | Switch/show current `kubectl` context |
| `kn [namespace]` | Switch/show current `kubectl` namespace |
| `apt-maintenance` | `apt update && upgrade && autoremove && autoclean` |
| `brew-maintenance` | `brew update && upgrade && cleanup` (1-day max age) |
| `ecr-login` | Docker login to this account's ECR registry (region: `bash_aliases_ecr_region`) |
| `git-reset-author` | Amend the last commit to reset its author to the current git identity |

Deliberately **not** migrated: `alias k=kubectl` — already deployed by
`setup_kube-extra`, would just be a duplicate/conflicting `blockinfile`
target if repeated here.

`apt-maintenance` uses `apt -y upgrade` (non-interactive) — this workstation's
live `~/.bash_aliases` already had that refinement, which the source
`../dotfiles/.bash_aliases` this role was templated from never had pushed
back to it; kept the live version rather than regressing it.

## Variables

| Variable | Default | Description |
|----------|---------|--------------|
| `bash_aliases_ecr_region` | `eu-west-1` | AWS region for the `ecr-login` alias |

## Usage

```yaml
- name: Configure bash aliases
  ansible.builtin.import_role:
    name: configure_bash-aliases
  become: false
  tags:
    - bash-aliases
```

## Notes

- `apt-maintenance` and `ecr-login`/AWS-specific aliases are harmless but
  no-ops (or errors if actually run) on machines without `apt`/AWS creds —
  same as the original dotfiles file, no OS/context guarding is applied to
  the alias *definitions* themselves, only to their install-time
  dependencies (`libnotify-bin`).
