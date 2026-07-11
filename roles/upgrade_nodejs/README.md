# upgrade_nodejs

Upgrades the nvm-managed Node.js version and global npm packages.

Companion to `setup_nodejs-dev-tools` (initial install) and `upgrade_brew`
(upgrades the `nvm`/`pnpm` Homebrew formulae themselves — not the Node.js
version nvm manages, which is what this role handles).

## What it does

1. `nvm install {{ nodejs_version }} --reinstall-packages-from=current` — installs the latest matching Node.js version and carries over globally-installed npm packages from the currently active version
2. `nvm alias default {{ nodejs_version }}` — points the `default` alias at the new version
3. `nvm cache clear` — clears nvm's download cache
4. `npm update -g` — upgrades already-installed global npm packages to their latest versions (only runs if `nodejs_npm_global_packages` is non-empty)

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `nodejs_version` | `"lts/*"` | Node.js version to upgrade to — keep in sync with `setup_nodejs-dev-tools` |
| `nodejs_npm_global_packages` | `[]` | Only used to gate the `npm update -g` step — keep in sync with `setup_nodejs-dev-tools` |

## Usage

```yaml
- name: Upgrade Node.js via nvm and global npm packages
  ansible.builtin.import_role:
    name: upgrade_nodejs
  become: false
  tags:
    - upgrade
    - nodejs
```

## Notes

- `become: false` — all operations run in user space
- nvm is a shell function, not a normal `PATH` binary — tasks drive it via explicit `. nvm.sh` shell commands (`nvm_brew_prefix` registered from `brew --prefix nvm`), same pattern as `setup_nodejs-dev-tools`
- Requires `setup_nodejs-dev-tools` to have run first (nvm installed, `~/.nvm` initialized)
- `--reinstall-packages-from=current` is nvm's own mechanism for carrying npm globals across a Node version bump — no separate uninstall/reinstall step needed
