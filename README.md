# Automated Environment Setup Using Ansible

Ansible automation for setting up and maintaining developer and DevOps environments. Uses a modular **LEGO approach**: each role is self-contained and independently runnable via tags.

Supports two scenarios:
- **Local workstation** setup (localhost) — tested on **macOS** and **Debian 13 under WSL2** (Windows)
- **Distributed Kubernetes cluster** on bare-metal hosts (via Kubespray) — tested on **Debian 13 nodes**

## Architecture

![Homelab Architecture](docs/homelab-architecture.png)

> Regenerate: `source ~/.venv/devops/bin/activate && python3 docs/homelab-architecture.py`

## Documentation

| Guide | Description |
|-------|-------------|
| [Local Setup](docs/local-setup.md) | Local workstation installation — playbooks, tags, macOS/Linux differences |
| [Kubernetes Setup](docs/kube-setup.md) | Bare-metal cluster (Kubespray) and local dev cluster (k3s) |
| [Roles Reference](docs/roles.md) | Role naming conventions, structure, and full role inventory |
| [CI/CD](docs/ci-cd.md) | CI pipeline, linting, and release automation |
| [GitOps Architecture](docs/gitops-architecture.md) | GitOps design and ArgoCD integration |

## Tool Management Philosophy

| Method | macOS | Linux | When to use |
|--------|-------|-------|-------------|
| **APT** | — | ✓ | System-level, rarely changing packages; well-maintained in Debian repos |
| **Homebrew** | ✓ formula + cask | ✓ Linuxbrew formula | Frequently updated tools; tools not in APT or lagging upstream |
| **uv** | ✓ | ✓ | Python CLI tools and library packages |

> Rule of thumb: APT for system stability (Linux), Homebrew for freshness and macOS-native installs, uv for the Python ecosystem.

## Prerequisites

```bash
pip install -r requirements.txt
ansible-galaxy install -r requirements.yml

cp inventory/hosts.example inventory/hosts
cp inventory/group_vars/all/secrets.yml.example inventory/group_vars/all/secrets.yml
```

## Quick Start

### Local workstation

```bash
ansible-playbook playbooks/local-core.yml       # core: brew, docker, minimal packages, network, python-uv
ansible-playbook playbooks/local-dev.yml        # dev tooling: vscode, go, nodejs, rust, gh
ansible-playbook playbooks/local-cloud.yml      # cloud: terraform, aws, azure, gcp
ansible-playbook playbooks/local-kube.yml       # kube tools: kubectl, helm, argocd, flux
ansible-playbook playbooks/upgrade-local.yml    # upgrade brew + uv packages
```

→ Full guide: [docs/local-setup.md](docs/local-setup.md)

### Kubernetes cluster

```bash
ansible-playbook --ask-become-pass playbooks/prerequisite.yml   # SSH + sudo setup
ansible-playbook playbooks/k8s-nodes.yml                        # node configuration
ansible-playbook -b playbooks/k8s.yml                           # Kubespray cluster install
ansible-playbook playbooks/post-k8s.yml                         # Longhorn, Traefik, ArgoCD
```

→ Full guide: [docs/kube-setup.md](docs/kube-setup.md)

### Run specific roles with tags

```bash
ansible-playbook -t brew,docker playbooks/local-core.yml
ansible-playbook -t nodejs playbooks/local-dev.yml
ansible-playbook -t terraform,aws playbooks/local-cloud.yml
ansible-playbook --ask-become-pass -t ssh,sudo playbooks/prerequisite.yml
```

### Dry run

```bash
ansible-playbook --check playbooks/local-core.yml
ansible-playbook --syntax-check playbooks/local-core.yml
```
