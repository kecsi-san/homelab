# upgrade_python-uv

Upgrades all uv-managed CLI tools and library packages.

Covers **Tier 3** of the tool management strategy. Companion to `debian_upgrade` (APT) and `upgrade_brew` (Homebrew). See [Tool Management Philosophy](../../README.md#tool-management-philosophy).

## What it does

1. `uv tool upgrade --all`: upgrades all CLI tools to their latest versions
2. `uv pip install --upgrade`: upgrades all library packages in `~/.venv/devops`

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `uv_bin` | `/home/linuxbrew/.linuxbrew/bin/uv` | Path to the uv binary |
| `uv_venv_path` | `~/.venv/devops` | Path to the shared library venv |
| `uv_pip_packages` | see `defaults/main.yml` | List of packages to upgrade |

## Usage

```yaml
- name: Upgrade uv tools and packages
  ansible.builtin.import_role:
    name: upgrade_python-uv
  become: false
  tags:
    - upgrade
    - uv
```

## Notes

- `become: false`: all operations run in user space
- Keep `uv_pip_packages` in sync with `setup_python-uv/defaults/main.yml`
- `uv tool upgrade --all` upgrades every tool installed via `uv tool install`, not just those listed in `setup_python-uv`
