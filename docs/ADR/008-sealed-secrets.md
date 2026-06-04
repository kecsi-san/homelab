---
title: "008 — SealedSecrets for Secret Management"
type: adr
status: accepted
scope: [k8s, k3s]
created: 2026-05-10
updated: 2026-05-17
tags: [secrets, sealed-secrets, security, gitops]
---

# 008 — SealedSecrets for Secret Management

## Status

Accepted

## Context

A GitOps workflow requires all cluster state to be committed to a Git repository.
Kubernetes `Secret` objects contain base64-encoded (not encrypted) values — committing
them directly to a public repository would expose credentials, API tokens, and
connection strings. The homelab needed a way to store secrets safely in Git while
still allowing ArgoCD to sync them into the cluster.

Requirements:
- Secrets must be safe to commit to a **public** GitHub repository
- Decryption must happen **in-cluster** (no external secrets service needed)
- Compatible with ArgoCD sync workflow (ArgoCD applies the manifest; controller decrypts)
- Namespace-scoped by default (a secret sealed for one namespace cannot be decrypted in another)
- Cluster-specific (a k8s-sealed secret cannot be decrypted by the k3s controller, and vice versa)
- Minimal operational overhead for a single-operator homelab

## Decision

Use **Bitnami Sealed Secrets** (controller + `kubeseal` CLI) on both clusters:

- Controller deployed via Helm (`sealed-secrets/sealed-secrets` chart) managed by ArgoCD
- Controller generates a unique RSA-4096 key pair per cluster at bootstrap
- `kubeseal` CLI encrypts a `Secret` against the cluster's public key → `SealedSecret` CR
- `SealedSecret` CRs committed to Git; controller decrypts them in-cluster → native `Secret`
- Key backup at `~/sealed-secrets-key-backup.yaml` (kept off-repo, restored after cluster rebuild)

Sealing workflow:
```bash
kubectl create secret generic my-secret --namespace my-ns \
  --from-literal=KEY=value --dry-run=client -o yaml | \
  kubeseal --format yaml \
    --context "admin@k8s" \
    --controller-name sealed-secrets \
    --controller-namespace sealed-secrets > sealedsecret.yaml
```

Long encrypted data lines get `# yamllint disable-line rule:line-length` comments.

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| **HashiCorp Vault** | Full secrets management platform; requires Vault server, HA setup, unsealing procedure, agent sidecar or CSI driver; enormous operational overhead for a homelab; overkill when all secrets are static credentials |
| **External Secrets Operator (ESO)** | Syncs secrets from external providers (AWS SSM, GCP Secret Manager, Azure Key Vault, Vault); requires an external backend — adds a cloud dependency or Vault dependency; no external backend available on this homelab |
| **SOPS + AGE / GPG** | File-level encryption committed to Git; requires SOPS tooling in the CI/CD pipeline; ArgoCD has a SOPS plugin (helm-secrets) but it's not natively supported — adds complexity; `AGE` keys must be distributed to every operator workstation |
| **Kubernetes Secrets (plain, base64)** | Zero encryption; base64 is trivially reversible; completely unacceptable for a public repo |
| **Doppler / 1Password Secrets Automation** | SaaS-based; adds external service dependency; requires internet connectivity for every Secret reconciliation; SaaS cost for a homelab |

## Consequences

**Positive:**
- `SealedSecret` CRs are safe to commit to a public GitHub repo — the encrypted blob
  is decryptable only by the specific cluster's controller private key
- No external dependencies: decryption happens entirely in-cluster; no internet access
  required for secret reconciliation after initial bootstrap
- Namespace scoping prevents cross-namespace secret leakage: a SealedSecret sealed for
  `authentik` namespace cannot be used in `forgejo` namespace even if copied
- Cluster isolation: k8s-sealed secrets are indecipherable to the k3s controller;
  both clusters can use the same repo with no cross-contamination risk
- `kubeseal` is available as a Homebrew package; installed via `setup_kube-extra` role

**Negative / Trade-offs:**
- **Key backup is critical**: the controller's private key is not stored in Git; losing
  it (cluster rebuild without restore) means all SealedSecrets become permanently
  undecryptable; the `~/sealed-secrets-key-backup.yaml` file must be backed up externally
- **Re-sealing required per cluster**: any secret that must exist on both k8s and k3s
  must be sealed twice — once against each cluster context; there is no shared key
- **One-way encryption**: you cannot "view" a sealed secret; to retrieve the original
  value you must `kubectl get secret` on the live cluster (the controller decrypts it
  into a native Secret)
- **Context discipline required**: accidentally sealing with `--context admin@k3s` when
  you meant `admin@k8s` produces a SealedSecret that silently fails to decrypt on the
  wrong cluster; the controller logs the failure but the source-of-truth error is subtle
- Rotating a sealed secret requires re-running `kubeseal` and committing the updated file
