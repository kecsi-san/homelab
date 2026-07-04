# setup_iac-terraform

Installs Terraform, the Vault CLI, and core IaC security/quality tooling via Homebrew.

## What it does

Installs the following via Homebrew (Tier 2 — frequently updated), tapping `hashicorp/tap` first since HashiCorp formulae aren't in homebrew-core:

| Tool | Purpose |
|------|---------|
| `terraform` | Infrastructure as Code provisioning |
| `vault` | Vault CLI — talks to a remote Vault server (e.g. `vault.kecskemethy.hu`), doesn't run one locally |
| `terraform-docs` | Auto-generates documentation from Terraform modules |
| `tflint` | Terraform linter and static analysis |
| `trivy` | Vulnerability and misconfiguration scanner (replaces tfsec) |

> `checkov` (IaC security scanner) is handled by `setup_python-uv` as a `uv tool install` — no need to install it here.

If `iac_vault_addr` is set, exports `VAULT_ADDR` in `~/.bashrc` via an Ansible-managed block. Authentication (`vault login`) is still a manual, one-time step — not something this role does for you.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `iac_brew_packages` | see `defaults/main.yml` | List of Homebrew packages to install |
| `iac_vault_addr` | `""` | Vault server URL to export as `VAULT_ADDR`. Empty skips the `~/.bashrc` block entirely. |

## Usage

```yaml
- name: Setup IaC Terraform tooling
  ansible.builtin.import_role:
    name: setup_iac-terraform
  become: false
  tags:
    - iac
    - terraform
```

## Notes

- `become: false` — Homebrew runs in user space
- Requires Homebrew (`install_linuxbrew` role)
- See [Tool Management Philosophy](../../README.md#tool-management-philosophy)
