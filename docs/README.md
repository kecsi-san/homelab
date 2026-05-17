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

Operational documentation for deployed IDP services. Component comparisons and selection
rationale live in [Research → IDP Components](research/idp-components.md).

| Doc | Description |
|-----|-------------|
| [Status](IDP/status.md) | IDP component plan, deployment targets, build order, and achievements log |
| [PostgreSQL Access](IDP/postgres.md) | CNPG cluster access, connection runbook, common commands |
| [User Management](IDP/user-management.md) | Creating and managing users in Authentik |
| [Forgejo](IDP/forgejo.md) | tea CLI setup, OCI registry, CI runners, admin tasks |
| [Outline](IDP/outline.md) | Documentation strategy: what goes in Outline vs Git; operational notes |
| CI Pipelines | *(planned)* Semgrep + Trivy in Forgejo Actions; CI workflow patterns |
| CD Pipelines | *(planned)* Push-to-main → ArgoCD sync; deployment workflow for Python apps |
| Backstage | *(planned)* Service catalog — after minimal IDP is stable on k8s |

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
| [IDP Components](research/idp-components.md) | Component comparisons: Forgejo, Authentik, Outline, CNPG, SealedSecrets, etc. |
| [Dashboard Comparison](research/dashboard-comparison.md) | Homepage vs Glance vs Homarr vs Dashy vs Hajimari |
| [App Candidates](research/app-candidates.md) | Self-hosted app candidates evaluated for the homelab |
| [Homelab Research](research/homelab-research.md) | General homelab component research notes |
| [Cilium Migration Plan](research/rebuild_cilium_migration_plan.md) | Kubespray rebuild and Cilium CNI migration plan |
| [Python Project Templates 2026](research/python-project-templates-2026.md) | uv-based Python project template comparison and recommendation (7 templates) |

## Architecture Decisions

| Doc | Description |
|-----|-------------|
| [001 — Dual Cluster Topology](adr/001-dual-cluster-topology.md) | k8s (bare-metal HA) + k3s (local dev) dual cluster rationale |
| [002 — Kubespray as Provisioner](adr/002-kubespray-as-provisioner.md) | Kubespray vs kubeadm, k0s, RKE2, Talos for cluster provisioning |
| [003 — Cilium CNI Migration](adr/003-cilium-cni-migration.md) | Cilium eBPF + Hubble, migrated from Calico |
| [004 — Longhorn Storage](adr/004-longhorn-storage.md) | Longhorn distributed block storage vs NFS/OpenEBS/Rook-Ceph |
| [005 — Traefik Ingress](adr/005-traefik-ingress.md) | Traefik v3 with forwardAuth + cert-manager vs nginx/HAProxy/Istio |
| [006 — ArgoCD GitOps](adr/006-argocd-gitops.md) | ArgoCD app-of-apps pattern vs Flux/Fleet |
| [007 — CloudNativePG](adr/007-cloudnative-pg.md) | CNPG operator for PostgreSQL vs standalone/Zalando/CrunchyData |
| [008 — SealedSecrets](adr/008-sealed-secrets.md) | SealedSecrets for GitOps-safe secrets vs Vault/ESO/SOPS+AGE |
| [009 — Authentik IdP](adr/009-authentik-idp.md) | Authentik as SSO/OIDC IdP vs Keycloak/Kanidm/Zitadel/Authelia |
| [010 — Forgejo Git Server](adr/010-forgejo-git-server.md) | Forgejo as self-hosted Git + OCI registry + CI vs GitLab/Gitea |
| [011 — Outline Wiki](adr/011-outline-wiki.md) | Outline over Docmost (OIDC gated behind EE) for team wiki |
| [012 — Cloudflare Tunnel](adr/012-cloudflare-tunnel.md) | Cloudflare Tunnel + WARP vs port forwarding/Tailscale/WireGuard |
| [013 — Forgejo Actions Runner](adr/013-forgejo-actions-runner.md) | DinD sidecar runner pattern vs host Docker/k8s executor/Podman |

## Homelab

| Doc | Description |
|-----|-------------|
| [Architecture Diagram](homelab/homelab-architecture.png) | Full homelab architecture (rendered PNG) |
| [Architecture Source](homelab/homelab-architecture.py) | Python source for the architecture diagram |
| [Icons](homelab/icons/) | Service icons for homepage dashboard |
