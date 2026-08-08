# configure_fzf

Adds `fzf` shell integration to `~/.bashrc`: idempotent and symlink-aware.

## What it does

1. Resolves `~/.bashrc` path (follows symlinks)
2. Checks whether fzf init is already present
3. If not, appends a managed block: `eval "$(fzf --bash)"`

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `home` | `{{ ansible_env.HOME }}` | Path to user home directory |
| `bashrc_path` | `{{ home }}/.bashrc` | Path to `.bashrc` (auto-resolved if symlink) |

## Usage

```yaml
- name: Configure fzf
  ansible.builtin.import_role:
    name: configure_fzf
  become: false
  tags:
    - fzf
    - fancy
    - developer
```

## Notes

- Requires `fzf` to already be installed (e.g. via `setup_minimal` brew packages)
- Uses `blockinfile` with a named marker; safe to re-run
