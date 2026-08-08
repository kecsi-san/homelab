# setup_go-dev-tools

Installs Go development tooling via Homebrew.

## What it does

| Tool | Formula | Default | Purpose |
|------|---------|---------|---------|
| `go` | `go` | always | Go compiler + standard toolchain |
| `gopls` | `gopls` | always | Official Go language server (IDE integration) |
| `golangci-lint` | `golangci-lint` | always | Fast multi-linter aggregator |
| `delve` | `delve` | optional | Go debugger |
| `goreleaser` | `goreleaser` | optional | Release automation (builds, changelogs, GitHub releases) |
| `ko` | `ko` | optional | Build and push Go container images without a Dockerfile |
| `air` | `air` | optional | Live reload for Go apps during development |

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `go_dev_enabled` | `true` | Set to `false` to skip the role entirely |
| `go_brew_packages` | `[go, gopls, golangci-lint]` | Core packages; always installed |
| `go_optional_brew_packages` | all `false` | Optional tools; flip to `true` to install |

## Usage

```yaml
- name: Setup Go development tooling
  ansible.builtin.import_role:
    name: setup_go-dev-tools
  when: go_dev_enabled
  vars:
    go_dev_enabled: true
    go_optional_brew_packages:
      delve: false
      goreleaser: false
      ko: false
      air: false
  tags:
    - go
    - dev
```

## Notes

- `become: false`: all installs are user-space via Homebrew
- After install, ensure `$(go env GOPATH)/bin` is in your `PATH` for tools installed via `go install`
- `gopls` is required for VS Code Go extension and JetBrains GoLand IDE support
