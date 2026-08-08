# setup_rust-dev-tools

Installs Rust development tooling via the official `rustup` installer.

## What it does

| Tool | Source | Default | Purpose |
|------|--------|---------|---------|
| `rustup` | rustup.rs script | always | Toolchain manager; installs/updates rustc, cargo, rustfmt, clippy |
| `rustc` | via rustup | always | Rust compiler |
| `cargo` | via rustup | always | Build system and package manager |
| `rustfmt` | via rustup (default profile) | always | Code formatter |
| `clippy` | via rustup (default profile) | always | Linter / static analysis |
| `cargo-watch` | cargo install | optional | Watch for changes and re-run cargo commands |
| `cargo-edit` | cargo install | optional | `cargo add`, `cargo rm`, `cargo upgrade` |
| `cargo-nextest` | cargo install | optional | Faster parallel test runner |
| `cross` | cargo install | optional | Cross-compilation via Docker |
| `bacon` | cargo install | optional | Background cargo check watcher |
| `sccache` | cargo install | optional | Shared compilation cache |

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `rust_dev_enabled` | `true` | Set to `false` to skip the role entirely |
| `rustup_profile` | `default` | Install profile: `minimal`, `default`, or `complete` |
| `rustup_toolchain` | `stable` | Toolchain channel: `stable`, `beta`, or `nightly` |
| `rust_cargo_tools` | all `false` | Optional tools installed via `cargo install` |

## Usage

```yaml
- name: Setup Rust development tooling
  ansible.builtin.import_role:
    name: setup_rust-dev-tools
  when: rust_dev_enabled
  vars:
    rust_dev_enabled: true
    rustup_profile: default
    rustup_toolchain: stable
    rust_cargo_tools:
      cargo-watch: false
      cargo-edit: false
      cargo-nextest: false
      cross: false
      bacon: false
      sccache: false
  tags:
    - rust
    - dev
```

## Notes

- `rustup` is installed to `~/.cargo/bin/rustup`: idempotent, skipped if already present
- `~/.cargo/bin` is added to `PATH` in `~/.bashrc` via an Ansible-managed block
- Optional cargo tools are compiled from source; first install can take several minutes
- `cross` requires Docker to be running for cross-compilation targets
- `--no-modify-path` is passed to the rustup installer since PATH is managed via the bashrc block
- Linux and macOS compatible; rustup is the official cross-platform Rust toolchain manager
