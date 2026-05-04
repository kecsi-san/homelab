# k8s Full Rebuild + Cilium CNI Migration Plan

Full cluster rebuild replacing Calico with Cilium CNI, with optional Kubernetes version upgrade. Recorded 2026-05-04.

---

## Current state

- 4 nodes: hped800g5/.18, hped800g62/.34, hppd600g6/.52 (control-plane), hped800g61/.36 (worker)
- k8s v1.33.7 (EOL ~2026-05-28), Kubespray release-2.29, **Calico CNI**, kube-vip v0.8.9
- kube-vip API VIP: 192.168.1.100
- kube-vip LoadBalancer VIP: 192.168.1.101 (Traefik)
- All apps managed by ArgoCD from `kube-gitops/k8s/`

---

## Impact assessment

### No impact (CNI-agnostic)

Everything at the app layer survives a full rebuild untouched — ArgoCD re-syncs from git:

- Traefik, ArgoCD, Headlamp, Homepage, Longhorn
- cert-manager, external-dns, Reloader, Renovate
- All IngressRoutes, TLS certs, Cloudflare tunnel

### Low impact (config tweak)

**kube-vip** — still required for API VIP (192.168.1.100). Its LoadBalancer role for `.101` can either:
- **Stay as-is** (keep kube-vip for both API VIP + service LB) — no gitops change needed
- **Migrate to Cilium LB-IPAM** — removes one component; requires changing Traefik service annotation:

  ```yaml
  # Current (kube-vip)
  kube-vip.io/loadbalancerIPs: "192.168.1.101"

  # With Cilium LB-IPAM (requires CiliumLoadBalancerIPPool CRD + annotation)
  # See Cilium docs for exact annotation
  ```

### High impact — Sealed Secrets key migration

The Sealed Secrets controller generates a unique private key per cluster. A fresh install creates a **new key**, making existing SealedSecrets in git unreadable.

Current sealed secrets in repo:
- `kube-gitops/k8s/external-dns/cloudflare-api-token-sealed.yaml`

**Option A — Export and restore (recommended):**

```bash
# Step 1: Before rebuild — export the key
kubectl get secret -n sealed-secrets \
  -l sealedsecrets.bitnami.com/sealed-secrets-key \
  -o yaml > sealed-secrets-key-backup.yaml
# Store this file securely (NOT in git)

# Step 2: After rebuild — restore before ArgoCD first sync
kubectl apply -f sealed-secrets-key-backup.yaml
kubectl rollout restart deployment -n sealed-secrets
# Now existing SealedSecrets in git can be decrypted as before
```

**Option B — Re-seal all secrets:**

After rebuild, re-seal each secret from the raw value using the new cluster's public key. Simpler but requires having raw secret values available.

### Longhorn data

Currently no stateful workloads (no databases deployed), so a full wipe is clean. If real data existed, VolSync backup would be required first.

---

## Kubernetes version upgrade

### Version landscape (as of 2026-05-04)

| k8s version | EOL | Kubespray support | Notes |
|-------------|-----|-------------------|-------|
| v1.33 | ~2026-05-28 | v2.29 (current) | **Current cluster — at EOL** |
| v1.34 | 2026-10-27 | v2.30, v2.31 | Only 5 months runway, not worth targeting |
| v1.35 | 2027-02-28 | v2.31 (default) | ✅ **Recommended target** |
| v1.36 | 2027-06-28 | v2.31 (supported) | Released 2026-04-22 — too fresh, some experimental parts in Kubespray |

**Recommended: v1.35.4** — the Kubespray v2.31.0 default. Best-tested path, 9+ months of EOL runway, all your apps are compatible.

v1.36 is technically available in Kubespray v2.31 but only 2 weeks old as of this writing — wait for a patch release (v1.36.1+) before targeting it.

### Impact on your stack

**Your gitops manifests are entirely unaffected.** No core Kubernetes APIs used by your stack are removed in v1.33 → v1.35 or v1.36.

| Change | Versions | Impact |
|--------|----------|--------|
| Traefik IngressRoute CRDs (`traefik.io/v1alpha1`) | — | Traefik-owned CRDs, unaffected by k8s API changes |
| ArgoCD, cert-manager, Longhorn, Sealed Secrets CRDs | — | Operator-owned CRDs, unaffected |
| `apps/v1` Deployments, `v1` Services/ConfigMaps | — | Stable APIs, no changes |
| `StorageVersionMigration v1alpha1` removed | v1.35 | Not used by your stack |
| `scheduling.k8s.io/v1alpha1` removed | v1.36 | Not used by your stack |
| Portworx in-tree plugin removed | v1.36 | You use Longhorn, not Portworx |
| cgroups v1 deprecated (`failCgroupV1: true` default) | v1.35 | Ubuntu 22.04+ uses cgroups v2 — check with `stat -fc %T /sys/fs/cgroup` on each node. Should return `cgroup2fs`, not `tmpfs`. |

### cgroups v2 check — verified 2026-05-04

All 4 nodes confirmed `cgroup2fs`. No action required.

### Kubespray version bump

Update `requirements.yml` to point to `release-2.31`:

```yaml
# requirements.yml
- name: kubernetes-sigs/kubespray
  src: https://github.com/kubernetes-sigs/kubespray
  scm: git
  version: release-2.31
```

---

## Kubespray config change

One-line change in `inventory/group_vars/k8s_cluster/k8s-net-calico.yml` → switch to Cilium:

```yaml
# inventory/group_vars/k8s_cluster/k8s-cluster.yml
kube_network_plugin: cilium
```

Optional but recommended additions:

```yaml
# Replace kube-proxy with Cilium (eBPF-native, better performance)
cilium_kube_proxy_replacement: strict

# Enable Hubble (Cilium's observability UI + CLI)
cilium_enable_hubble: true
cilium_hubble_install: true
cilium_hubble_relay: true
```

---

## Rebuild procedure

1. **Export Sealed Secrets key** — store securely off-cluster
2. ~~Verify cgroups v2~~ — ✅ done 2026-05-04, all nodes `cgroup2fs`
3. **Update `requirements.yml`** — bump Kubespray to `release-2.31`
4. **Update Kubespray config** — set `kube_network_plugin: cilium`, `kube_version: v1.35.4`, optionally enable kube-proxy replacement + Hubble
5. **Run `ansible-galaxy install -r requirements.yml`** to pull new Kubespray release
6. **Run `reset-k8s.yml`** to tear down existing cluster
7. **Run `k8s.yml`** to rebuild cluster at v1.35.4 with Cilium
8. **Restore Sealed Secrets key** — apply backup before ArgoCD bootstraps
9. **Run `post-k8s.yml`** — installs ArgoCD, then bootstraps gitops (`root.yaml`)
10. **ArgoCD syncs** — all apps reconcile from git automatically

---

## Decision point: kube-vip vs Cilium LB-IPAM

| | Keep kube-vip for LB | Switch to Cilium LB-IPAM |
|---|---|---|
| Component count | kube-vip does both API VIP + service LB | kube-vip for API VIP only; Cilium handles service LB |
| Gitops change | None | Update Traefik service annotation |
| Complexity | Simpler (status quo) | Slightly more Cilium config |
| Community trend | Being phased out in Cilium clusters | Preferred in new Cilium setups |

**Recommendation:** Keep kube-vip for both on first rebuild (less risk). Migrate to Cilium LB-IPAM in a follow-up once Cilium is stable.

---

## What to consider adding during the rebuild

Based on homelab research (`docs/homelab-research.md`), rebuild is a good forcing function for:

- **VolSync** — PVC backup (prerequisite before adding stateful apps)
- **CloudNativePG** — Postgres operator (needed by Immich, Paperless-NGX, etc.)
- **kube-prometheus-stack + Grafana** — monitoring (biggest current gap)
- **Hubble** — Cilium network observability (free if enabling Cilium anyway)
