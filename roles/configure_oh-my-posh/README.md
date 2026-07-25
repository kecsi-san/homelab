# configure_oh-my-posh

Installs an oh-my-posh prompt theme and wires it into `~/.bashrc`.

## What it does

1. Creates the themes directory (`~/.poshthemes` by default)
2. Copies `epam.omp.yaml`, the selected `default_omp_theme`, and (if set) `omp_theme_override` from `files/` to the themes directory
3. Selects the active theme: `omp_theme_override` if set, else `epam.omp.yaml` if `ansible_hostname` starts with `EP`, else `default_omp_theme`
4. Checks if oh-my-posh is already initialised in `~/.bashrc`
5. If not, appends a managed block: `eval "$(oh-my-posh init bash --config <theme>)"`

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `omp_themes_dir` | `~/.poshthemes` | Directory where theme files are stored |
| `default_omp_theme` | `pluto.omp.yaml` | Theme filename to deploy and activate |
| `omp_theme_override` | *(unset)* | Optional per-host/group escape hatch, takes priority over the EPAM/default heuristic (e.g. an EPAM host that still wants a non-epam.omp.yaml theme) |
| `home` | `{{ ansible_env.HOME }}` | User home directory |

## Available themes

Theme files are in `roles/configure_oh-my-posh/files/`:
- `pluto.omp.yaml` (default) — self-adapts its `os` segment background to the actual OS/distro via `background_templates` keyed on `.Icon`/`.WSL` (palette: `debian-red`, `ubu-orange`, `rpi-red`, `mac-gray`, `microsoft-blue`), so one file covers every non-EPAM host instead of maintaining a static theme per OS
- `epam.omp.yaml` — EPAM-branded variant (own palette, "❮ epam ❯" badge segments), selected automatically for hostnames starting with `EP`

## Usage

```yaml
- name: Configure oh-my-posh
  ansible.builtin.import_role:
    name: configure_oh-my-posh
  become: false
  tags:
    - omp
    - fancy
    - developer
```

## Notes

- Requires `oh-my-posh` to already be installed (via `setup_minimal` brew packages)
- Uses `blockinfile` with a named marker — safe to re-run
- Override `default_omp_theme` in group_vars to use a different theme per host group
