---
title: "Quick Start"
type: guide
scope: [local, k3s, k8s]
---

# Quick Start

## Prerequisites

```bash
pip install -r requirements.txt
ansible-galaxy install -r requirements.yml
cp inventory/group_vars/all/secrets.yml.example inventory/group_vars/all/secrets.yml
# Edit secrets.yml — see the workflow guides for field descriptions
```

## Local workstation

```bash
ansible-playbook playbooks/local-core.yml       # core: brew, docker, minimal packages, network, python-uv
ansible-playbook playbooks/local-dev.yml        # dev tooling: vscode, go, nodejs, rust, gh
ansible-playbook playbooks/local-cloud.yml      # cloud: terraform, aws, azure, gcp
ansible-playbook playbooks/local-kube.yml       # kube tools: kubectl, helm, argocd, flux
ansible-playbook playbooks/upgrade-local.yml    # upgrade brew + uv packages
```

## Local k3s cluster

```bash
ansible-playbook playbooks/k3s.yml
ansible-playbook playbooks/post-k3s.yml
```

## Bare-metal homelab cluster

```bash
ansible-playbook playbooks/configure-router.yml           # DNS — must run before k8s.yml
ansible-playbook --ask-become-pass playbooks/prerequisite.yml
ansible-playbook playbooks/k8s-nodes.yml
ansible-playbook playbooks/pre-k8s.yml
ansible-playbook -b playbooks/k8s.yml
ansible-playbook playbooks/post-k8s.yml
```

## Running specific roles with tags

```bash
ansible-playbook -t brew,docker playbooks/local-core.yml
ansible-playbook -t nodejs playbooks/local-dev.yml
ansible-playbook -t terraform,aws playbooks/local-cloud.yml
ansible-playbook --ask-become-pass -t ssh,sudo playbooks/prerequisite.yml
```

See [CLAUDE.md](../../CLAUDE.md) for the full tag reference across all playbooks.
