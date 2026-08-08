# install_nerd_fonts

Installs Nerd Font variants via Homebrew Cask for use with terminal themes like oh-my-posh.

## What it does

Loops over the `nerd_fonts` dict in `defaults/main.yml` and installs every font whose value is `true` via `community.general.homebrew_cask`.

By default only two fonts are enabled:
- **Meslo LG Nerd Font** (`font-meslo-lg-nerd-font`); recommended for oh-my-posh
- **Fira Code Nerd Font** (`font-fira-code-nerd-font`); ligatures

## Enabling additional fonts

Override in `group_vars/local.yml` (merge dict, not replace):

```yaml
nerd_fonts:
  font-meslo-lg-nerd-font: true
  font-fira-code-nerd-font: true
  font-jetbrains-mono-nerd-font: true
  font-hack-nerd-font: true
```

Full list of 51 available fonts is in `defaults/main.yml`.

## Usage

```yaml
- name: Install nerd fonts
  ansible.builtin.import_role:
    name: install_nerd_fonts
  become: false
  tags:
    - fonts
    - desktop
```

## Notes

- Requires Linuxbrew to be installed (`install_linuxbrew` role)
- `become: false`: Homebrew Cask installs fonts into the user's font directory
- Fonts are primarily useful on desktop/developer machines, not headless servers
- Part of **Tier 2** of the tool management strategy (Homebrew-managed). See [Tool Management Philosophy](../../README.md#tool-management-philosophy).
