# Documentation Index

## IDP

| Doc | Description |
|-----|-------------|
| [Status](IDP/status.md) | IDP component decisions, deployment targets, and build order |
| [Research](IDP/research.md) | Component comparisons and recommendations (Forgejo, Authentik, Docmost, etc.) |

## Ansible Workflows

| Doc | Description |
|-----|-------------|
| [Dev/DevOps Workstation](ansible/devenv.md) | Set up a local workstation — macOS or Debian/WSL2 |
| [Local k3s Cluster](ansible/k3s.md) | Single-node k3s cluster for local development (WSL2 + macOS) |
| [4-Node Homelab Cluster](ansible/k8s-homelab.md) | Bare-metal HA cluster, GitOps stack, Cloudflare Tunnel |
| [Roles Reference](ansible/roles.md) | Role naming conventions, structure, and full role inventory |
| [CI/CD](ansible/ci-cd.md) | CI pipeline, linting, pre-commit hooks, and changelog automation |

## Research

| Doc | Description |
|-----|-------------|
| [Dashboard Comparison](research/dashboard-comparison.md) | Homepage vs Glance vs Homarr vs Dashy vs Hajimari |
| [App Candidates](research/app-candidates.md) | Self-hosted app candidates evaluated for the homelab |
| [Homelab Research](research/homelab-research.md) | General homelab component research notes |
| [Cilium Migration Plan](research/rebuild_cilium_migration_plan.md) | Kubespray rebuild and Cilium CNI migration plan |

## Homelab

| Doc | Description |
|-----|-------------|
| [Architecture Diagram](homelab/homelab-architecture.png) | Full homelab architecture (rendered PNG) |
| [Architecture Source](homelab/homelab-architecture.py) | Python source for the architecture diagram |
| [Icons](homelab/icons/) | Service icons for homepage dashboard |
