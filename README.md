# Automated Environment Setup Using Ansible

[![GitHub Tag](https://img.shields.io/github/v/tag/kecsi-san/ansible-env-setup)](https://github.com/kecsi-san/ansible-env-setup/releases)
[![Lint](https://github.com/kecsi-san/ansible-env-setup/actions/workflows/lint.yml/badge.svg)](https://github.com/kecsi-san/ansible-env-setup/actions/workflows/lint.yml)
[![License](https://img.shields.io/github/license/kecsi-san/ansible-env-setup)](LICENSE)
![GitHub last commit](https://img.shields.io/github/last-commit/kecsi-san/ansible-env-setup)
![GitHub repo size](https://img.shields.io/github/repo-size/kecsi-san/ansible-env-setup)
[![Renovate](https://img.shields.io/badge/renovate-enabled-brightgreen?logo=renovatebot)](https://renovatebot.com)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://pre-commit.com)

Ansible automation for setting up and maintaining developer/DevOps environments and a bare-metal Kubernetes homelab. Uses a modular **LEGO approach**: each role is self-contained and independently runnable via tags.

## Workflows

| Guide | Description |
|-------|-------------|
| [Dev/DevOps Workstation](docs/devenv.md) | Set up a local workstation — macOS or Debian/WSL2 |
| [Local k3s Cluster](docs/k3s.md) | Single-node k3s cluster for local development (WSL2 + macOS) |
| [4-Node Homelab Cluster](docs/k8s-homelab.md) | Bare-metal HA cluster, GitOps stack, Cloudflare Tunnel |

## Reference

| Guide | Description |
|-------|-------------|
| [Roles](docs/roles.md) | Role naming conventions, structure, and full role inventory |
| [CI/CD](docs/ci-cd.md) | CI pipeline, linting, pre-commit hooks, and changelog automation |

---

## Tool Management Philosophy

| Method | macOS | Linux | When to use |
|--------|-------|-------|-------------|
| **APT** | — | ✓ | System-level, rarely changing packages; well-maintained in Debian repos |
| **Homebrew** | ✓ formula + cask | ✓ Linuxbrew formula | Frequently updated tools; tools not in APT or lagging upstream |
| **uv** | ✓ | ✓ | Python CLI tools and library packages |

> APT for system stability (Linux), Homebrew for freshness and macOS-native installs, uv for the Python ecosystem.

---

## Prerequisites

```bash
pip install -r requirements.txt
ansible-galaxy install -r requirements.yml

cp inventory/group_vars/all/secrets.yml.example inventory/group_vars/all/secrets.yml
# Edit secrets.yml — see the workflow guides for what each field does
```

---

## Quick Start

### Local workstation

```bash
ansible-playbook playbooks/local-core.yml       # core: brew, docker, minimal packages, network, python-uv
ansible-playbook playbooks/local-dev.yml        # dev tooling: vscode, go, nodejs, rust, gh
ansible-playbook playbooks/local-cloud.yml      # cloud: terraform, aws, azure, gcp
ansible-playbook playbooks/local-kube.yml       # kube tools: kubectl, helm, argocd, flux
ansible-playbook playbooks/upgrade-local.yml    # upgrade brew + uv packages
```

### Local k3s cluster

```bash
ansible-playbook playbooks/k3s.yml
ansible-playbook playbooks/post-k3s.yml
```

### Bare-metal homelab cluster

```bash
ansible-playbook playbooks/configure-router.yml          # DNS — run before k8s.yml
ansible-playbook --ask-become-pass playbooks/prerequisite.yml
ansible-playbook playbooks/k8s-nodes.yml
ansible-playbook playbooks/pre-k8s.yml
ansible-playbook -b playbooks/k8s.yml
ansible-playbook playbooks/post-k8s.yml
```

### Run specific roles with tags

```bash
ansible-playbook -t brew,docker playbooks/local-core.yml
ansible-playbook -t nodejs playbooks/local-dev.yml
ansible-playbook -t terraform,aws playbooks/local-cloud.yml
ansible-playbook --ask-become-pass -t ssh,sudo playbooks/prerequisite.yml
```
