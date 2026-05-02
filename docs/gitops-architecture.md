# GitOps Architecture — yourdomain.com Homelab

This document describes the planned architecture for managing both Kubernetes clusters
using Ansible for infrastructure bootstrapping and ArgoCD for continuous GitOps delivery.

---

## Clusters

| Cluster | Purpose | Nodes | Version |
|---------|---------|-------|---------|
| **homelab** (`k8s.yourdomain.com`) | Bare-metal HA cluster | 3 control-plane + 1 worker | k8s v1.33.7 (Kubespray) |
| **local** (`k3s.yourdomain.com`) | Local dev / experimentation | 1 node (WSL2) | k3s v1.34.6 |

Both clusters follow the same component model to keep configuration and skills transferable.

---

## Two-Layer Model

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 1 — Infrastructure (this repo: ansible-env-setup)    │
│                                                             │
│  post-k8s.yml → Traefik, Sealed Secrets, Headlamp (Helm)   │
│               → ArgoCD app-of-apps bootstrap (pending)      │
│                                                             │
│  post-k3s.yml → ArgoCD (Helm)                              │
│               → app-of-apps bootstrap (kubectl apply)       │
│                 ArgoCD then installs Traefik, Sealed        │
│                 Secrets, and Headlamp from kube-gitops/     │
│                                                             │
│  Re-run only for: cluster rebuilds, node changes,           │
│  component version upgrades                                 │
└──────────────────────────────┬──────────────────────────────┘
                               │ ArgoCD watches GitOps repo
┌──────────────────────────────▼──────────────────────────────┐
│  Layer 2 — GitOps (kube-gitops/ in this repo)               │
│                                                             │
│  kube-gitops/k8s/    kube-gitops/k3s/                       │
│    → root.yaml         → root.yaml   (bootstrap App)        │
│    → apps/             → apps/       (child Applications)   │
│    → values/           → values/     (Helm values per app)  │
│                                                             │
│  ArgoCD self-manages after initial bootstrap                │
└─────────────────────────────────────────────────────────────┘
```

**Principle:** Ansible owns the platform layer (install once, rarely touch).
ArgoCD owns everything running on top (continuous reconciliation).

---

## Component Inventory

### Homelab (k8s.yourdomain.com)

| Component | Version | Installed by | Managed by |
|-----------|---------|-------------|------------|
| Kubernetes | v1.33.7 | Kubespray (`k8s.yml`) | Kubespray |
| kube-vip | v0.8.9 | Kubespray | Kubespray |
| Calico CNI | — | Kubespray | Kubespray |
| ArgoCD | v2.14.5 | Kubespray addon (`addons.yml`) | ArgoCD (self-manages) |
| cert-manager | v1.15.3 | Kubespray addon (`addons.yml`) | ArgoCD |
| Traefik | latest stable | Ansible `post-k8s.yml` | ArgoCD |
| Sealed Secrets | latest stable | Ansible `post-k8s.yml` | ArgoCD |
| Headlamp | 0.40.0 | Ansible `post-k8s.yml` | ArgoCD |

### Local k3s (k3s.yourdomain.com)

| Component | Version | Installed by | Managed by |
|-----------|---------|-------------|------------|
| k3s | v1.34.6 | Ansible `k3s.yml` | Ansible |
| ArgoCD | v2.13.1 | Ansible `post-k3s.yml` (`setup_argocd`) | ArgoCD (self-manages) |
| Traefik | chart 34.4.1 | ArgoCD (`kube-gitops/k3s/apps/`) | ArgoCD |
| Sealed Secrets | chart 2.16.1 | ArgoCD (`kube-gitops/k3s/apps/`) | ArgoCD |
| Headlamp | chart 0.40.0 | ArgoCD (`kube-gitops/k3s/apps/`) | ArgoCD |

> **Note:** k3s ships Traefik built-in. It is disabled at install time (`k3s_disable_traefik: true`)
> so our ArgoCD-managed instance is the only one running.

---

## DNS and Domain Structure

| Cluster | Base domain | Wildcard cert covers |
|---------|-------------|---------------------|
| Homelab | `k8s.yourdomain.com` | `*.k8s.yourdomain.com` |
| k3s local | `k3s.yourdomain.com` | `*.k3s.yourdomain.com` |

### Planned service hostnames

| Service | Homelab URL | k3s URL |
|---------|------------|---------|
| ArgoCD | `argocd.k8s.yourdomain.com` | `argocd.k3s.yourdomain.com` |
| Headlamp | `headlamp.k8s.yourdomain.com` | `headlamp.k3s.yourdomain.com` |
| Traefik dashboard | `traefik.k8s.yourdomain.com` | `traefik.k3s.yourdomain.com` |

New services get a hostname in the appropriate subdomain — no new IPs needed.

### DNS records required (Cloudflare)

**Homelab (k8s) — internet-facing via Cloudflare Tunnel:**

```
CNAME  argocd.k8s.kecskemethy.org    →  <tunnel-id>.cfargotunnel.com  (proxied)
CNAME  headlamp.k8s.kecskemethy.org  →  <tunnel-id>.cfargotunnel.com  (proxied)
CNAME  longhorn.k8s.kecskemethy.org  →  <tunnel-id>.cfargotunnel.com  (proxied)
```

LAN access uses router DNS overrides (A records → 192.168.1.101) and bypasses
Cloudflare entirely.

**k3s (local dev) — LAN only:**

```
A  *.k3s.kecskemethy.org  →  192.168.1.25  (router DNS, LAN only)
```

---

## SSL — Automated Certificate Renewal

cert-manager handles all certificate lifecycle. No manual cert management.

### Challenge type: DNS-01 via Cloudflare

HTTP-01 is not viable (clusters are LAN-only, not reachable from the internet).
DNS-01 proves domain ownership by creating a TXT record in Cloudflare via API token.

```
cert-manager  →  Cloudflare API (DNS-01 challenge)  →  Let's Encrypt
     ↓
Wildcard certificate: *.k8s.yourdomain.com
     ↓
Stored as Kubernetes Secret in each namespace that needs it
     ↓
Traefik serves the cert for all IngressRoute hosts
```

### cert-manager resources (managed by ArgoCD in GitOps repo)

```yaml
# ClusterIssuer — one per cluster
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
      - dns01:
          cloudflare:
            apiTokenSecretRef:
              name: cloudflare-api-token   # Sealed Secret
              key: api-token

# Certificate — wildcard per cluster
kind: Certificate
metadata:
  name: wildcard-k8s-yourdomain-com
  namespace: traefik   # Traefik reads it from here
spec:
  secretName: wildcard-k8s-yourdomain-com-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - "*.k8s.yourdomain.com"
```

### Cloudflare API token

Scoped minimally — only the permissions cert-manager needs:

```
Zone → Zone → Read
Zone → DNS  → Edit
```
Scope: specific zone `yourdomain.com` only.

The token is stored as a **Sealed Secret** — encrypted with the cluster's public key,
safe to commit to the GitOps repo. Never stored in plaintext.

---

## Secrets Management — Sealed Secrets

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) consists of:
- A controller running in the cluster (holds the private key)
- `kubeseal` CLI on the workstation (encrypts secrets with the cluster's public key)

### Workflow

```bash
# 1. Create the raw secret (never committed)
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=<your-token> \
  --dry-run=client -o yaml > /tmp/cf-token.yaml

# 2. Seal it (safe to commit)
kubeseal --format yaml < /tmp/cf-token.yaml > clusters/homelab/cert-manager/cloudflare-api-token-sealed.yaml

# 3. Commit the sealed secret to the GitOps repo
# The controller decrypts it in-cluster — plaintext never leaves the machine
```

### Important: sealed secrets are cluster-specific

A secret sealed for homelab cannot be decrypted by k3s. Each cluster needs its own
sealed version of shared secrets (Cloudflare token, etc.).

---

## Traffic Flow

### Internet request (homelab, via Cloudflare Tunnel)

```
Browser: https://argocd.k8s.kecskemethy.org
         │
         ▼
Cloudflare edge  (CNAME → <tunnel-id>.cfargotunnel.com)
         │  outbound tunnel
         ▼
cloudflared pod  (Deployment in cluster, namespace: cloudflared)
         │  https://traefik.traefik.svc.cluster.local
         ▼
Traefik: TLS termination (wildcard cert from cert-manager)
         Host: argocd.k8s.kecskemethy.org → argocd-server:80 (ClusterIP)
         │
         ▼
ArgoCD pod
```

### LAN request (homelab, direct)

```
Browser: https://argocd.k8s.kecskemethy.org
         │
         ▼
Router DNS: argocd.k8s.kecskemethy.org → 192.168.1.101  (local override)
         │
         ▼
kube-vip ARP: 192.168.1.101 → Traefik pod (LoadBalancer service)
         │
         ▼
Traefik → ArgoCD pod  (same path as above from here)
```

### kube-vip + Traefik relationship

kube-vip and Traefik are complementary, not competing:

| Layer | Tool | Responsibility |
|-------|------|---------------|
| L4 — IP announcement | kube-vip | ARP-announces 192.168.1.101 on the LAN |
| L7 — HTTP routing + TLS | Traefik | Routes by hostname, terminates SSL |

kube-vip configuration is unchanged — it simply announces one IP instead of many.

---

## IP Plan (Homelab)

| IP | Role | Status |
|----|------|--------|
| 192.168.1.100 | kube-vip API VIP | Unchanged |
| 192.168.1.101 | Traefik LoadBalancer | Reassigned from ArgoCD |
| 192.168.1.102 | — | Free (was Headlamp) |

### Migration order (zero-conflict cutover)

```
1. Deploy Traefik via Ansible (service type: ClusterIP initially)
2. Patch ArgoCD service → ClusterIP  (releases .101)
3. Patch Traefik service → LoadBalancer, annotation: kube-vip.io/loadbalancerIPs: 192.168.1.101
4. Patch Headlamp service → ClusterIP  (releases .102)
5. Apply ArgoCD app-of-apps → ArgoCD picks up IngressRoutes from GitOps repo
6. Add DNS A records in Cloudflare: *.k8s.yourdomain.com → 192.168.1.101
```

---

## GitOps Directory Structure (kube-gitops/ in this repo)

GitOps manifests live in `kube-gitops/` within this repo — no separate repository needed.
ArgoCD uses the multi-source pattern: chart from Helm repo, values from this git repo.

```
kube-gitops/
├── k8s/                                # Bare-metal homelab cluster
│   ├── root.yaml                       # Bootstrap Application — applied once by Ansible
│   ├── apps/                           # ArgoCD watches this directory
│   │   ├── traefik.yaml
│   │   ├── longhorn.yaml
│   │   ├── headlamp.yaml
│   │   ├── sealed-secrets.yaml
│   │   └── cert-manager.yaml
│   └── values/                         # Helm values per app
│       ├── traefik.yaml
│       ├── longhorn.yaml
│       ├── headlamp.yaml
│       ├── sealed-secrets.yaml
│       └── cert-manager.yaml
└── k3s/                                # Local dev cluster
    ├── root.yaml
    ├── apps/
    │   ├── traefik.yaml
    │   ├── headlamp.yaml
    │   └── sealed-secrets.yaml
    └── values/
        ├── traefik.yaml
        ├── headlamp.yaml
        └── sealed-secrets.yaml
```

To upgrade a component: bump `targetRevision` in `apps/<component>.yaml` and update
`values/<component>.yaml` if needed — one PR, ArgoCD applies it automatically.

---

## Ansible Roles

| Role | Playbook | Status | Purpose |
|------|---------|--------|---------|
| `setup_traefik` | `post-k8s.yml` | ✅ Done | Install Traefik via Helm (homelab bootstrap) |
| `setup_sealed-secrets` | `post-k8s.yml` | ✅ Done | Install Sealed Secrets controller via Helm (homelab bootstrap) |
| `setup_headlamp` | `post-k8s.yml` | ✅ Done | Install Headlamp via Helm (homelab bootstrap) |
| `setup_argocd` | `post-k3s.yml` | ✅ Done | Install ArgoCD via Helm; shows initial admin password |
| `setup_argocd-apps` | `post-k3s.yml` ✅ / `post-k8s.yml` 🔲 | ✅ k3s done | Apply `kube-gitops/{k3s,k8s}/root.yaml` to hand off to ArgoCD |

---

## Decisions Made

| Decision | Choice | Reason |
|----------|--------|--------|
| Ingress controller | Traefik | k3s-native, actively maintained, supports Ingress + Gateway API |
| Secrets | Sealed Secrets | Simple, no external dependency, safe to commit |
| SSL challenge | Cloudflare DNS-01 | Clusters are LAN-only; HTTP-01 requires public access |
| Cert scope | Wildcard per cluster | One cert covers all services; easier to manage |
| External access (k8s) | Cloudflare Tunnel | No open ports, home IP hidden; see docs/cloudflare-tunnel.md |
| External access (k3s) | LAN-only | Local dev cluster; not internet-facing |
| GitOps location | `kube-gitops/` in this repo (not a separate repo) | Solo homelab: one repo is simpler; ansible-lint excludes the directory |
| ArgoCD bootstrap | Ansible applies app-of-apps once | Clean handoff: Ansible bootstraps, ArgoCD self-manages after |

---

## Future Work / Not In Scope Yet

- **Cloudflare Tunnel (k3s)** — add internet access to local dev cluster (k8s done)
- **Envoy Gateway** — migrate k3s to Gateway API for learning; homelab to follow
- **Longhorn** — distributed block storage already installed on homelab, wire into GitOps
- **Monitoring stack** — Grafana + Prometheus via ArgoCD
- **k8s-nodes.yml security parity** — `local-security.yml` equivalent for remote hosts
