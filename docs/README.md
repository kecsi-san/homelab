---
title: "Documentation Index"
type: reference
status: stable
scope: [general]
created: 2026-05-15
updated: 2026-05-17
tags: [index, navigation]
---

# Documentation Index

See [STANDARDS.md](STANDARDS.md) for the documentation standard, front-matter spec, and
Diátaxis type definitions used across all docs.

## IDP

| Doc | Description |
|-----|-------------|
| [Status](IDP/status.md) | IDP component decisions, deployment targets, and build order |
| [Research](IDP/research.md) | Component comparisons and recommendations (Forgejo, Authentik, Outline, etc.) |
| [PostgreSQL Access](IDP/postgres.md) | CNPG cluster access, connection runbook, common commands |
| [User Management](IDP/user-management.md) | Creating and managing users in Authentik |

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
| [Python Project Templates 2026](research/python-project-templates-2026.md) | uv-based Python project template comparison and recommendation |

## Architecture Decisions

| Doc | Description |
|-----|-------------|
| *(none yet — add to `docs/adr/` using MADR format from STANDARDS.md)* | |

## Homelab

| Doc | Description |
|-----|-------------|
| [Architecture Diagram](homelab/homelab-architecture.png) | Full homelab architecture (rendered PNG) |
| [Architecture Source](homelab/homelab-architecture.py) | Python source for the architecture diagram |
| [Icons](homelab/icons/) | Service icons for homepage dashboard |
