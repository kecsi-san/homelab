# setup_nodejs-dev-tools

Installs Node.js, selecting between two install methods via
`nodejs_install_method`:

- **`homebrew-nvm`** (default, workstations) — Node.js managed via **nvm**
  (not a fixed Homebrew formula) so multiple versions can be installed and
  switched per-project; `pnpm` and the optional tools remain standalone
  Homebrew binaries.
- **`apt-nodesource`** (servers) — Node.js installed system-wide from the
  NodeSource apt repo, root-owned, single version, no per-project switching.
  Homebrew-only options (`nodejs_brew_packages`,
  `nodejs_optional_brew_packages`) don't apply to this method.

## What it does

### `homebrew-nvm` method

| Tool | Source | Default | Purpose |
|------|--------|---------|---------|
| `nvm` | brew | always | Node version manager |
| Node.js (`nodejs_version`) | `nvm install` | always | Node.js runtime + npm, set as the `default` nvm alias |
| `pnpm` | brew | always | Fast, disk-efficient package manager (standalone binary, not nvm-managed) |
| `yarn` | brew | optional | Alternative package manager |
| `typescript` | brew | optional | TypeScript compiler (`tsc`) + type checker |
| `tsx` | brew | optional | Run TypeScript files directly (ts-node alternative) |
| `eslint` | brew | optional | JavaScript/TypeScript linter |
| `prettier` | brew | optional | Opinionated code formatter |
| npm global packages | `npm install -g` (nvm-managed npm) | optional | Any packages listed in `nodejs_npm_global_packages` |

### `apt-nodesource` method

| Tool | Source | Default | Purpose |
|------|--------|---------|---------|
| Node.js (`nodejs_apt_major_version`) | NodeSource apt repo (via `setup_apt_repos`) | always | Node.js runtime + npm, system-wide; purges Debian's own node packages first |
| npm global packages | `community.general.npm`, `global: true` | optional | Any packages listed in `nodejs_npm_global_packages` |

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `nodejs_dev_enabled` | `true` | Set to `false` to skip the role entirely |
| `nodejs_install_method` | `"homebrew-nvm"` | `"homebrew-nvm"` or `"apt-nodesource"` |
| `nodejs_version` | `"lts/*"` | Node.js version installed via nvm — only used for `homebrew-nvm` |
| `nodejs_apt_major_version` | `"24"` | NodeSource major version line — only used for `apt-nodesource` |
| `nodejs_apt_purge_distro_packages` | `true` | Passed through to `setup_apt_repos` — only used for `apt-nodesource` |
| `nodejs_brew_packages` | `[pnpm]` | Standalone Homebrew packages — only used for `homebrew-nvm` |
| `nodejs_optional_brew_packages` | all `false` | Optional tools — only used for `homebrew-nvm` |
| `nodejs_npm_global_packages` | `[]` | Extra packages to install globally via npm — both methods |

## Usage

```yaml
# Workstation (default)
- name: Setup Node.js development tooling
  ansible.builtin.import_role:
    name: setup_nodejs-dev-tools
  when: nodejs_dev_enabled
  vars:
    nodejs_dev_enabled: true
    nodejs_install_method: homebrew-nvm
    nodejs_version: "lts/*"
    nodejs_optional_brew_packages:
      yarn: false
      typescript: false
      tsx: false
      eslint: false
      prettier: false
    nodejs_npm_global_packages: []
  tags:
    - nodejs
    - dev
```

```yaml
# Server
- name: Setup Node.js
  ansible.builtin.import_role:
    name: setup_nodejs-dev-tools
  vars:
    nodejs_install_method: apt-nodesource
    nodejs_apt_major_version: "24"
    nodejs_npm_global_packages:
      - thumbsup
  tags:
    - nodejs
```

## Notes

- `homebrew-nvm`: `become: false`, all installs are user-space. nvm is a
  shell function sourced into interactive shells, not a normal `PATH`
  binary — tasks drive it via explicit `. nvm.sh` shell commands
  (`nvm_brew_prefix` registered from `brew --prefix nvm`), not an Ansible
  module. `community.general.npm` isn't used either, for the same reason:
  nvm-managed `npm` lives under `~/.nvm/versions/node/<version>/bin`, not a
  path the module can find without sourcing nvm first.
- `apt-nodesource`: `become: true`, system-wide like any other apt package.
  Delegates the repo/package work to `setup_apt_repos` (see that role's
  README for the purge-vs-pin rationale) and installs global npm packages
  directly via `community.general.npm`, since apt-installed node/npm are
  already on the normal system `PATH`.
- `pnpm` is preferred over npm for workspace projects — faster installs,
  content-addressable store. Homebrew-only, not available under
  `apt-nodesource`.
- `eslint` and `prettier` are usually installed per-project via
  devDependencies; use global install only for standalone linting scripts.
- Companion role: `upgrade_nodejs` upgrades Node.js and global npm packages
  via whichever method installed it; `upgrade_brew` covers the `nvm`/`pnpm`
  Homebrew formulae themselves (only relevant to `homebrew-nvm`).
