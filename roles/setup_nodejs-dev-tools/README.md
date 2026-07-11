# setup_nodejs-dev-tools

Installs Node.js development tooling. Node.js itself is managed via **nvm**
(not a fixed Homebrew formula) so multiple versions can be installed and
switched per-project; `pnpm` and the optional tools remain standalone
Homebrew binaries.

## What it does

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

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `nodejs_dev_enabled` | `true` | Set to `false` to skip the role entirely |
| `nodejs_version` | `"lts/*"` | Node.js version installed via nvm (e.g. `"lts/*"`, `"22"`, `"22.10.0"`) |
| `nodejs_brew_packages` | `[pnpm]` | Standalone Homebrew packages — always installed |
| `nodejs_optional_brew_packages` | all `false` | Optional tools — flip to `true` to install |
| `nodejs_npm_global_packages` | `[]` | Extra packages to install globally via npm |

## Usage

```yaml
- name: Setup Node.js development tooling
  ansible.builtin.import_role:
    name: setup_nodejs-dev-tools
  when: nodejs_dev_enabled
  vars:
    nodejs_dev_enabled: true
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

## Notes

- `become: false` — all installs are user-space
- nvm is a shell function sourced into interactive shells, not a normal `PATH` binary — tasks drive it via explicit `. nvm.sh` shell commands (`nvm_brew_prefix` registered from `brew --prefix nvm`), not an Ansible module. `community.general.npm` isn't used either, for the same reason: nvm-managed `npm` lives under `~/.nvm/versions/node/<version>/bin`, not a path the module can find without sourcing nvm first
- `pnpm` is preferred over npm for workspace projects — faster installs, content-addressable store
- `eslint` and `prettier` are usually installed per-project via devDependencies; use global install only for standalone linting scripts
- Companion role: `upgrade_nodejs` (in `upgrade-local.yml`) upgrades the nvm-managed Node.js version and global npm packages; `upgrade_brew` covers the `nvm`/`pnpm` Homebrew formulae themselves
