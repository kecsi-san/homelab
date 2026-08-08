# setup_iac-extra

Installs additional IaC tooling via Homebrew; complements `setup_iac-terraform`.

## What it does

Installs the following via Homebrew (Tier 2; frequently updated):

| Tool | Purpose |
|------|---------|
| `opentofu` | Open-source drop-in replacement for Terraform |
| `terragrunt` | Terraform wrapper for DRY configurations |
| `terrascan` | Compliance and security violation detection for IaC |
| `tfupdate` | Updates version constraints in Terraform configurations |

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `iac_extra_brew_packages` | see `defaults/main.yml` | List of Homebrew packages to install |

## Usage

```yaml
- name: Setup extra IaC tooling
  ansible.builtin.import_role:
    name: setup_iac-extra
  become: false
  tags:
    - iac
    - iac-extra
```

## Notes

- `become: false`: Homebrew runs in user space
- Requires Homebrew (`install_linuxbrew` role)
- See [Tool Management Philosophy](../../README.md#tool-management-philosophy)
