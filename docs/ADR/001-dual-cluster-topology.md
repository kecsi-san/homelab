---
title: "001 — Dual Cluster Topology: k8s + k3s"
type: adr
status: accepted
scope: [k8s, k3s]
created: 2026-04-01
updated: 2026-05-17
tags: [architecture, cluster, k8s, k3s, topology]
---

# 001 — Dual Cluster Topology: k8s + k3s

## Status

Accepted

## Context

The homelab needed a Kubernetes environment that served two distinct purposes:

1. **Production-grade homelab services** — always-on services (monitoring, git, wiki,
   SSO, recipe manager, etc.) running on physical hardware with real storage, proper HA,
   and Cloudflare tunnel access.
2. **Local development and experimentation** — a fast, disposable cluster on the
   developer workstation (WSL2/macOS) for testing new manifests, debugging deployments,
   and learning new IDP components before promoting to production.

Running both purposes on the same cluster creates tension: a broken experiment can
affect production services; production constraints (HA, storage class, node count) make
experimentation slow and expensive.

Hardware available:
- 4 physical nodes (3× HP EliteDesk 800 G5, 1× HP ProDesk 600 G6) on the home LAN
- Developer workstation running WSL2 (Ubuntu) with ~12 GB free for k3s

## Decision

Maintain two completely separate clusters:

| Cluster | Runtime | Nodes | Purpose |
|---|---|---|---|
| **k8s** | Kubespray 2.31 + k8s 1.35 + Cilium | 4 bare-metal nodes | Production homelab — always-on services + full IDP + Backstage |
| **k3s** | k3s native (WSL2) / k3d (macOS) | 1 node (localhost) | Development — IDP stack mirror, manifest testing, CI experimentation |

Both clusters are managed by ArgoCD with the same app-of-apps GitOps pattern, pointing
to separate paths in the repo (`kube-gitops/k8s/` and `kube-gitops/k3s/`).

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| Single k8s cluster for everything | No isolation between experimental and production workloads; breaking changes in experiments affect live services |
| Single k3s cluster (local only) | k3s single-node has no HA, no distributed storage; not representative of production; services not available outside the workstation |
| Kind / minikube for local dev | Even more ephemeral; no persistent storage; cannot run a full IDP stack; not realistic enough to validate production manifests |
| Separate physical k3s node | Unnecessary hardware cost; WSL2 provides sufficient isolation for development purposes |
| Namespace-based isolation on k8s | Does not isolate CNI, storage class, or node resources; a misbehaving workload in one namespace affects others |

## Consequences

**Positive:**
- Production services are unaffected by experimentation and debugging on k3s
- The k3s cluster provides a fast, representative environment that closely mirrors k8s
  (same manifests with only storage class and replica count differences)
- Both clusters share the same GitOps patterns, Helm charts, and SealedSecrets workflows
  (with separate SealedSecrets encryption keys per cluster)
- Developers can validate complete IDP flows locally before deploying to k8s

**Negative / Trade-offs:**
- Maintaining two clusters doubles the GitOps path maintenance (every new component
  needs manifests in both `kube-gitops/k8s/` and `kube-gitops/k3s/`)
- SealedSecrets must be sealed separately for each cluster
  (`--context admin@k8s` vs `--context admin@k3s`)
- k3s lags behind k8s in IDP component deployment — the mirroring is manual and
  happens in a second pass
- WSL2 k3s networking has known limitations with port mapping; k3d (macOS) requires
  explicit `--port` flags
