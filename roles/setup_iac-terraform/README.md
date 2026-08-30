# setup_iac-terraform

Installs Terraform, the Vault CLI, and core IaC security/quality tooling via Homebrew.

## What it does

Installs the following via Homebrew (Tier 2; frequently updated), tapping `hashicorp/tap` first since HashiCorp formulae aren't in homebrew-core:

| Tool | Purpose |
|------|---------|
| `terraform` | Infrastructure as Code provisioning |
| `vault` | Vault CLI; talks to a remote Vault server (e.g. `vault.k*.hu`), doesn't run one locally |
| `terraform-docs` | Auto-generates documentation from Terraform modules |
| `tflint` | Terraform linter and static analysis |
| `trivy` | Vulnerability and misconfiguration scanner (replaces tfsec) |

> `checkov` (IaC security scanner) is handled by `setup_python-uv` as a `uv tool install`: no need to install it here.

If `iac_vault_addr` is set, exports `VAULT_ADDR` in `~/.bashrc` via an Ansible-managed block, and adds a `vault-login` alias (`vault login -method=userpass username={{ admin_user }}`) as a shortcut for the actual login step; replaces the old `../dotfiles` `vault_login.sh`/`vault_env.sh` scripts (which pointed at a former-employer's LDAP-auth dev Vault, not reusable as-is). Authentication itself is still a manual, interactive step (needs your password); the alias just saves typing the command.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `iac_brew_packages` | see `defaults/main.yml` | List of Homebrew packages to install |
| `iac_vault_addr` | `""` | Vault server URL to export as `VAULT_ADDR`. Empty skips both `~/.bashrc` blocks (address and `vault-login` alias) entirely. |
| `admin_user` | vaulted in `secrets.yml`/`local.yml` | Username baked into the `vault-login` alias |

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

- `become: false`: Homebrew runs in user space
- Requires Homebrew (`install_linuxbrew` role)
- See [Tool Management Philosophy](../../README.md#tool-management-philosophy)
