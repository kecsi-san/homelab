# configure_mc-theme

Downloads the gruvbox256 Midnight Commander skin. Migrated from the old
`../dotfiles` `bin/mc-gruvbox-skin-setup.sh` (see homelab `TODO.md`
"Dotfiles migration").

## What it does

Downloads [Dornat/midnight-commander-gruvbox-skin](https://github.com/Dornat/midnight-commander-gruvbox-skin)'s
`gruvbox256.ini` to `~/.local/share/mc/skins/gruvbox256.ini`. `mc` itself is
already installed by `setup_minimal`: this role only handles the skin file.

Unlike the original script, this does **not** launch `mc` interactively; that was a one-time "try it now" convenience in the source script, not
something to automate. To actually enable it:

```
mc -S gruvbox256
```

or permanently: Options → Appearance → Skin → `gruvbox256`.

## Usage

```yaml
- name: Configure Midnight Commander theme
  ansible.builtin.import_role:
    name: configure_mc-theme
  become: false
  tags:
    - mc-theme
```
