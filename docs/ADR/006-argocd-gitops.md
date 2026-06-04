---
title: "006 — ArgoCD for GitOps"
type: adr
status: accepted
scope: [k8s, k3s]
created: 2026-04-01
updated: 2026-05-17
tags: [argocd, gitops, ci-cd, deployment]
---

# 006 — ArgoCD for GitOps

## Status

Accepted

## Context

All cluster workloads should be managed declaratively from a Git repository — any
manual `kubectl apply` that is not committed to Git is invisible, unrepeatable, and
lost on cluster rebuild. This requires a GitOps controller that:

- Continuously reconciles cluster state against Git
- Detects and alerts on (or auto-corrects) configuration drift
- Supports **app-of-apps** pattern for managing many applications from a single root
- Has a **UI** for operational visibility without reading raw YAML
- Supports Helm chart sources, raw manifests, and Kustomize
- Fits a single-operator homelab (minimal operational overhead)

## Decision

Use **ArgoCD** on both clusters, deployed via Helm (`argo/argo-helm` chart), with the
**app-of-apps** pattern:

- Root app (`root.yaml`) watches `kube-gitops/{k8s,k3s}/apps/` directory
- Each file in `apps/` is an ArgoCD `Application` pointing to a specific path in the repo
- ArgoCD self-manages its own Application (bootstrapped once via `setup_argocd-apps` role)
- Auto-sync enabled with `prune: true` and `selfHeal: true` on all apps

ArgoCD runs in **insecure mode** (no TLS at the ArgoCD level; Traefik terminates TLS).
Source repository: `https://github.com/kecsi-san/homelab.git` (public; no credentials needed).

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| **Flux v2** | No built-in UI; operational visibility requires separate tooling (Flux CLI, Weave GitOps); the app-of-apps equivalent (`Kustomization` chaining) is less intuitive; smaller homelab community than ArgoCD |
| **Rancher Fleet** | Tightly coupled to Rancher; importing clusters without Rancher management plane is possible but awkward; overkill for a 2-cluster homelab |
| **Manual kubectl apply** | Not idempotent; lost on rebuild; no drift detection; error-prone as the app count grows |
| **Helm-only (no GitOps)** | Helm manages charts well but does not watch for drift or auto-reconcile; would require manual `helm upgrade` on every change |
| **Jenkins X / Tekton** | CI/CD pipelines, not GitOps controllers; solve a different problem |

## Consequences

**Positive:**
- ArgoCD UI at `argocd.kecskemethy.org` shows all 25 apps with sync/health status at
  a glance; invaluable during cluster rebuilds and after deployments
- App-of-apps pattern means adding a new service is a single file in `apps/` and a
  directory of manifests; no central registry to update
- `prune: true` ensures deleted manifest files result in deleted k8s resources; no orphaned
  resources accumulate after renaming or removing apps
- `selfHeal: true` reverts any manual `kubectl apply` that diverges from Git;
  enforces Git-as-source-of-truth discipline
- Hard refresh via annotation patch (`argocd.argoproj.io/refresh: hard`) provides a
  lightweight alternative to logging in via ArgoCD CLI when authentication is unavailable

**Negative / Trade-offs:**
- ArgoCD's Helm chart management creates "sync waves" complexity when CRDs must install
  before CRD-using resources; worked around with `ServerSideApply=true` for CNPG and
  `ignoreDifferences` for fields that Kubernetes controllers mutate after apply
- ArgoCD insecure mode: the API server is accessible without TLS at the pod level;
  Traefik TLS termination provides encryption in transit but the ArgoCD API pod itself
  does not validate TLS — acceptable behind Traefik but not in a multi-tenant environment
- GitHub as the source repo means ArgoCD requires internet access to poll for changes;
  an outage blocks new deployments (but does not affect running workloads)
- The ArgoCD admin password is auto-generated and stored in a k8s Secret; it is printed
  once during bootstrap by the `setup_argocd` role and must be saved manually
- After cluster rebuild, ArgoCD must be re-bootstrapped and all SealedSecrets
  re-decrypted (requires restoring the SealedSecrets key before ArgoCD syncs)
