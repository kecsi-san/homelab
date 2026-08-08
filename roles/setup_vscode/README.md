# setup_vscode

> **Status: Incomplete**: see notes below before using.

Installs VS Code, deploys user settings, and installs extensions.

Local-only role; not included in `k8s-nodes.yml`.

## What it does

1. Adds the Microsoft apt repository and GPG key
2. Installs `code` via apt
3. Installs extensions via `code --install-extension`
4. Deploys `settings.json` to `~/.config/Code/User/settings.json`

## Extensions installed

| Extension | Purpose |
|-----------|---------|
| `docker.docker` | Docker management |
| `github.copilot-chat` | GitHub Copilot Chat |
| `hashicorp.terraform` | Terraform language support |
| `ms-azuretools.vscode-containers` | Dev containers |
| `ms-azuretools.vscode-docker` | Docker (Microsoft) |
| `ms-kubernetes-tools.vscode-kubernetes-tools` | Kubernetes tooling |
| `ms-python.debugpy` | Python debugger |
| `ms-python.isort` | Python import sorter |
| `ms-python.python` | Python language support |
| `ms-python.vscode-pylance` | Python language server |
| `ms-python.vscode-python-envs` | Python environment manager |
| `ms-toolsai.jupyter` | Jupyter notebooks |
| `ms-toolsai.jupyter-keymap` | Jupyter keybindings |
| `ms-toolsai.jupyter-renderers` | Jupyter output renderers |
| `ms-toolsai.vscode-jupyter-cell-tags` | Jupyter cell tags |
| `ms-toolsai.vscode-jupyter-slideshow` | Jupyter slideshow |
| `ms-vscode.makefile-tools` | Makefile support |
| `redhat.vscode-yaml` | YAML language support |
| `searking.preview-vscode` | File preview |
| `tim-koehler.helm-intellisense` | Helm chart intellisense |

## Settings

| Setting | Value |
|---------|-------|
| Color theme | One Dark Pro Mix |
| Icon theme | Material Icon Theme |
| Terminal font | MesloLGS NF |
| Git autofetch | enabled |
| Telemetry | disabled |

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `vscode_bin` | `code` | Path to VS Code binary |
| `vscode_extensions` | see `defaults/main.yml` | List of extensions to install |

## Usage

```yaml
- name: Setup VS Code
  ansible.builtin.import_role:
    name: setup_vscode
  tags:
    - vscode
```

## Notes

- `code --install-extension` is idempotent; skips already-installed extensions
- Extension installation requires `code` to be on PATH
- On WSL2, extensions are installed into `~/.vscode-server/extensions/`

## Known limitation

This role installs VS Code on Linux and deploys settings to `~/.config/Code/User/settings.json`.
However, in a WSL2 setup, VS Code runs on **Windows**: its settings and extensions live on the Windows side.
Configuring the Windows VS Code from a Linux Ansible playbook requires WinRM or Windows SSH, which is out of scope for now.

**Current state:** tasks are written but the approach needs rethinking for WSL2 environments.
