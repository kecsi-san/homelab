# setup_cloud-azure

Installs Azure CLI tooling for local development and infrastructure work.

## What it does

| Tool | Formula | Default | Purpose |
|------|---------|---------|---------|
| `azure-cli` | `azure-cli` | always | Main Azure CLI (`az`) |
| `azd` | `azure-dev` | optional | Azure Developer CLI; scaffold/deploy workflow |
| `bicep` | `bicep` | optional | Bicep IaC language (alternative to ARM templates) |
| `azcopy` | `azcopy` | optional | High-performance Azure Storage copy tool |
| `kubelogin` | `kubelogin` | optional | Azure AD auth plugin for kubectl (AKS) |

All tools installed via Homebrew; cross-platform (Linux + macOS).

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `azure_enabled` | `true` | Set to `false` to skip the role entirely |
| `azure_brew_packages` | `[azure-cli]` | Core packages; always installed |
| `azure_optional_brew_packages` | all `false` | Optional tools; flip to `true` to install |

## Usage

```yaml
- name: Setup Azure cloud tooling
  ansible.builtin.import_role:
    name: setup_cloud-azure
  when: azure_enabled
  vars:
    azure_enabled: true
    azure_optional_brew_packages:
      azure-dev: false
      bicep: false
      azcopy: false
      kubelogin: false
  tags:
    - cloud
    - azure
```

## Notes

- `become: false`: all Homebrew installs are user-space
- `azure-cli` is also installable from the Microsoft apt repo (`apt_repo_microsoft` in `setup_apt_repos`) but Homebrew is used here for cross-platform consistency
- `kubelogin` is required for AKS clusters using Azure AD / Entra ID authentication
