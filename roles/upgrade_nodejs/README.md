# upgrade_nodejs

Upgrades Node.js and its global npm packages, via whichever method installed
it (`nodejs_install_method`, kept in sync with `setup_nodejs-dev-tools`).

Companion to `setup_nodejs-dev-tools` (initial install) and `upgrade_brew`
(upgrades the `nvm`/`pnpm` Homebrew formulae themselves — not the Node.js
version nvm manages, which is what this role handles for the `homebrew-nvm`
method).

## What it does

### `homebrew-nvm` method (workstations)

1. `nvm install {{ nodejs_version }} --reinstall-packages-from=current` — installs the latest matching Node.js version and carries over globally-installed npm packages from the currently active version
2. `nvm alias default {{ nodejs_version }}` — points the `default` alias at the new version
3. `nvm cache clear` — clears nvm's download cache
4. `npm update -g` — upgrades already-installed global npm packages to their latest versions (only runs if `nodejs_npm_global_packages` is non-empty)

### `apt-nodesource` method (servers)

1. Re-runs `setup_apt_repos` with `apt_repo_nodesource: true` and the (bumped)
   `nodejs_apt_major_version` — apt resolves and installs the new major
   version from the NodeSource repo. This is the entire "upgrade" for this
   method; there's no separate uninstall step.
2. Force-reinstalls each entry in `nodejs_npm_global_packages` at
   `state: latest` — native addons (e.g. `better-sqlite3`) are tied to
   Node's ABI, so they need a fresh install after a major version bump, not
   just being left alone. This will also pick up the latest published
   version of the package itself (matching the `npm update -g` semantics of
   the nvm path) — if you have local patches applied on top of a global
   package (see e.g. `thumbsup`'s patches in the photoarchive2 theme repo),
   reapply them after this runs.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `nodejs_install_method` | `"homebrew-nvm"` | `"homebrew-nvm"` or `"apt-nodesource"` — keep in sync with `setup_nodejs-dev-tools` |
| `nodejs_version` | `"lts/*"` | Node.js version to upgrade to via nvm — only used for `homebrew-nvm` |
| `nodejs_apt_major_version` | `"24"` | NodeSource major version line to upgrade to — only used for `apt-nodesource` |
| `nodejs_apt_purge_distro_packages` | `true` | Passed through to `setup_apt_repos` — only used for `apt-nodesource` |
| `nodejs_npm_global_packages` | `[]` | Packages to upgrade/reinstall — keep in sync with `setup_nodejs-dev-tools` |

## Usage

```yaml
- name: Upgrade Node.js via nvm and global npm packages
  ansible.builtin.import_role:
    name: upgrade_nodejs
  become: false
  vars:
    nodejs_install_method: homebrew-nvm
    nodejs_version: "lts/*"
  tags:
    - upgrade
    - nodejs
```

```yaml
- name: Upgrade Node.js via NodeSource apt repo
  ansible.builtin.import_role:
    name: upgrade_nodejs
  become: true
  vars:
    nodejs_install_method: apt-nodesource
    nodejs_apt_major_version: "24"
    nodejs_npm_global_packages:
      - thumbsup
  tags:
    - upgrade
    - nodejs
```

## Notes

- `homebrew-nvm`: `become: false`, all operations run in user space. nvm is a
  shell function, not a normal `PATH` binary — tasks drive it via explicit
  `. nvm.sh` shell commands (`nvm_brew_prefix` registered from
  `brew --prefix nvm`), same pattern as `setup_nodejs-dev-tools`. Requires
  `setup_nodejs-dev-tools` to have run first (nvm installed, `~/.nvm`
  initialized). `--reinstall-packages-from=current` is nvm's own mechanism
  for carrying npm globals across a Node version bump — no separate
  uninstall/reinstall step needed.
- `apt-nodesource`: `become: true`, system-wide like any other apt package.
  Delegates the actual repo/package work to `setup_apt_repos` — see that
  role's README for the purge-vs-pin rationale.
