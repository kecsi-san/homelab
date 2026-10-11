---
title: "Documentation Index"
type: reference
status: stable
scope: [general]
created: 2026-05-15
updated: 2026-10-11
tags: [index, navigation]
---

# Documentation Index

See [STANDARDS.md](STANDARDS.md) for the documentation standard, front-matter spec, and
Diátaxis type definitions used across all docs.

## IDP

Operational documentation for deployed IDP services. Component comparisons and selection
rationale live in [Research → IDP Components](research/homelab-idp-components.md).

| Doc | Description |
|-----|-------------|
| [Status](IDP/status.md) | IDP component plan, deployment targets, build order, and achievements log |
| [PostgreSQL Access](IDP/postgres.md) | CNPG cluster access, connection runbook, common commands |
| [User Management](IDP/user-management.md) | Creating and managing users in Authentik |
| [Forgejo](IDP/forgejo.md) | tea CLI setup, OCI registry, CI runners, admin tasks |
| [Outline](IDP/outline.md) | *Superseded by Wiki.js.* Documentation strategy and operational notes, kept for history |
| [CI Pipelines](IDP/ci-pipelines.md) | Forgejo Actions setup; Python template adaptation; Semgrep + Trivy (planned) |
| Continuous delivery | No separate doc: delivery is GitOps. A push to `main` is synced by ArgoCD, see [ADR 006](ADR/006-argocd-gitops.md) and the [GitOps stack](ansible/k8s-homelab.md) |
| Backstage | ✅ Deployed on k8s (see [Status](IDP/status.md)); service catalog; custom image built via Forgejo Actions CI |

## Ansible Workflows

| Doc | Description |
|-----|-------------|
| [Quick Start](ansible/quickstart.md) | First-time setup guide; where to begin |
| [Dev/DevOps Workstation](ansible/devenv.md) | Set up a local workstation; macOS or Debian/WSL2 |
| [Local k3s Cluster](ansible/k3s.md) | Single-node k3s cluster for local development (WSL2 + macOS) |
| [4-Node Homelab Cluster](ansible/k8s-homelab.md) | Bare-metal HA cluster, GitOps stack, Cloudflare Tunnel |
| [Roles Reference](ansible/roles.md) | Role naming conventions, structure, and full role inventory |
| [CI/CD](ansible/ci-cd.md) | CI pipeline, linting, pre-commit hooks, and changelog automation |

## How-tos

Cross-cutting operational procedures and runbooks.

| Doc | Description |
|-----|-------------|
| [k8s Rebuild + Cilium Migration](howtos/cilium-migration.md) | Full cluster rebuild runbook and Cilium CNI migration plan |
| [EC2 Rebuild Plan](howtos/ec2-rebuild-plan.md) | Replacing the original 2016 EC2 edge node with a fully codified instance; phased migration plan |
| [EC2 EBS Volumes](howtos/ec2-ebs-volumes.md) | Storage/volume layout design for the new EC2 edge node |
| [Vault Secrets Architecture](howtos/vault-secrets-architecture.md) | Vault mount/policy design and the `secrets.yml` → Vault migration plan |

## Research

| Doc | Description |
|-----|-------------|
| [Homelab Repos Survey](research/homelab-repos-survey.md) | General homelab component research: popular repos, common patterns |
| [IDP Components](research/homelab-idp-components.md) | Component comparisons: Forgejo, Authentik, Outline, CNPG, SealedSecrets, etc. |
| [Dashboard Comparison](research/homelab-dashboard-comparison.md) | Homepage vs Glance vs Homarr vs Dashy vs Hajimari |
| [App Candidates](research/homelab-apps-candidates.md) | Self-hosted app candidates evaluated for the homelab |
| [Monitoring Survey](research/homelab-monitoring-survey.md) | Monitoring stacks in popular homelab repos: Prometheus, Loki, Gatus, Kromgo |
| [Monitoring Stack](research/homelab-monitoring-stack.md) | Monitoring stack research and selection rationale for this repo |
| [Wiki Software](research/homelab-wiki-comparison.md) | Self-hosted wiki software comparison |
| [Cloud VPS Services Survey](research/cloud-vps-services-survey.md) | Cloud/VPS usage in homelab repos: VPN, email, DNS, provider trends (18 repos) |
| [Email Server Components](research/cloud-email-server-components.md) | Self-hosted email stack: Postfix, Dovecot, Rspamd, TLS, DNS requirements |
| [Python Project Templates](research/dev-python-templates.md) | uv-based Python project template comparison and recommendation (7 templates) |
| [Secret Store Comparison](research/homelab-secret-store-comparison.md) | HashiCorp Vault vs OpenBao; license, feature parity, ecosystem maturity |
| [Cloud Storage Comparison](research/homelab-cloud-storage-comparison.md) | Self-hosted file storage and collaboration software (why OpenCloud) |
| [Email Archive Software](research/email-archive-software.md) | Survey of self-hosted email archiving tools (Bichon and others) |

## Architecture Decisions

| Doc | Description |
|-----|-------------|
| [001: Dual Cluster Topology](ADR/001-dual-cluster-topology.md) | k8s (bare-metal HA) + k3s (local dev) dual cluster rationale |
| [002: Kubespray as Provisioner](ADR/002-kubespray-as-provisioner.md) | Kubespray vs kubeadm, k0s, RKE2, Talos for cluster provisioning |
| [003: Cilium CNI Migration](ADR/003-cilium-cni-migration.md) | Cilium eBPF + Hubble, migrated from Calico |
| [004: Longhorn Storage](ADR/004-longhorn-storage.md) | Longhorn distributed block storage vs NFS/OpenEBS/Rook-Ceph |
| [005: Traefik Ingress](ADR/005-traefik-ingress.md) | Traefik v3 with forwardAuth + cert-manager vs nginx/HAProxy/Istio |
| [006: ArgoCD GitOps](ADR/006-argocd-gitops.md) | ArgoCD app-of-apps pattern vs Flux/Fleet |
| [007: CloudNativePG](ADR/007-cloudnative-pg.md) | CNPG operator for PostgreSQL vs standalone/Zalando/CrunchyData |
| [008: SealedSecrets](ADR/008-sealed-secrets.md) | SealedSecrets for GitOps-safe secrets vs Vault/ESO/SOPS+AGE |
| [009: Authentik IdP](ADR/009-authentik-idp.md) | Authentik as SSO/OIDC IdP vs Keycloak/Kanidm/Zitadel/Authelia |
| [010: Forgejo Git Server](ADR/010-forgejo-git-server.md) | Forgejo as self-hosted Git + OCI registry + CI vs GitLab/Gitea |
| [011: Outline Wiki](ADR/011-outline-wiki.md) | *Superseded by Wiki.js.* Outline over Docmost (OIDC gated behind EE) for team wiki |
| [012: Cloudflare Tunnel](ADR/012-cloudflare-tunnel.md) | Cloudflare Tunnel + WARP vs port forwarding/Tailscale/WireGuard |
| [013: Forgejo Actions Runner](ADR/013-forgejo-actions-runner.md) | DinD sidecar runner pattern vs host Docker/k8s executor/Podman |

## Infrastructure map

The map lives in its own folder, see the [folder README](infra-map/README.md) for contents, regeneration and history.

| Doc | Description |
|-----|-------------|
| [Architecture Map (draw.io)](infra-map/homelab-architecture-v0.3-black.drawio) | Current infrastructure map, editable in diagrams.net (PNG preview next to it) |
| [Architecture Map Source](infra-map/homelab-architecture-drawio.py) | Python generator for the draw.io files (`link` and `block` variants) |
| [Older diagrams](infra-map/README.md#folder-contents) | Python `diagrams` versions v0.1 (light) and v0.2 (dark), kept for comparison |
| [Icons](infra-map/icons/) | Logos used by the infrastructure map |
