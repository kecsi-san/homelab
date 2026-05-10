# Workflow: 4-Node Bare-Metal Homelab Cluster

Full walkthrough for building and maintaining the bare-metal HA Kubernetes cluster
using Kubespray, followed by a GitOps app stack managed by ArgoCD.

---

## Architecture

![Homelab Architecture](homelab-architecture.png)

> Regenerate: `source ~/.venv/devops/bin/activate && python3 docs/homelab-architecture.py`

### Clusters

| Cluster | Purpose | Nodes | Version |
|---------|---------|-------|---------|
| **homelab** | Bare-metal HA cluster | 3 control-plane + 1 worker | k8s v1.35.4 (Kubespray release-2.31) |
| **local** | Local dev / experimentation | 1 node (WSL2) | k3s v1.34.6 |

### Traffic Flow

**LAN request (direct):**
```
Browser: https://argocd.<your-domain.tld>
    │
    ▼
MikroTik wildcard DNS: *.<your-domain.tld> → 192.168.1.101
    │
    ▼
kube-vip ARP: 192.168.1.101 → Traefik pod (LoadBalancer)
    │
    ▼
Traefik: TLS termination (per-service LE cert) → argocd-server:80
```

**Internet request (Cloudflare WARP / Tunnel):**
```
Browser: https://argocd.<your-domain.tld>
    │
    ▼
Cloudflare edge (CNAME → <tunnel-id>.cfargotunnel.com, proxied)
    │  outbound tunnel (cloudflared initiates, no open ports needed)
    ▼
cloudflared pod (namespace: cloudflared)
    │  https://traefik.traefik.svc.cluster.local (noTLSVerify: true)
    ▼
Traefik → ArgoCD pod
```

### IP Plan

| IP | Role |
|----|------|
| 192.168.1.100 | kube-vip API VIP (`api.k8s.<your-domain.tld>`) |
| 192.168.1.101 | Traefik LoadBalancer |
| 192.168.1.102 | Free |

### Split-Horizon DNS

| Client | Resolver | Resolves to | Path |
|--------|----------|-------------|------|
| LAN (DoH off) | MikroTik `192.168.1.1` | `192.168.1.101` | Direct to Traefik |
| Internet / WARP | Cloudflare public DNS | Cloudflare proxy IPs | Via Cloudflare Tunnel |

---

## GitOps App Stack

ArgoCD manages all apps via an app-of-apps pattern. Root app: `kube-gitops/k8s/root.yaml`.

| App | Namespace | Purpose |
|-----|-----------|---------|
| traefik | traefik | Ingress controller; LoadBalancer IP 192.168.1.101 via kube-vip |
| sealed-secrets | sealed-secrets | Encrypts secrets safe to commit |
| cert-manager + config | cert-manager | LE certs via DNS-01 challenge (Cloudflare API) |
| argocd | argocd | GitOps controller; insecure mode (Traefik terminates TLS) |
| longhorn | longhorn-system | Distributed block storage; default StorageClass |
| cloudflared | cloudflared | Cloudflare Tunnel (internet access, no open ports) |
| external-dns | external-dns | Auto-creates Cloudflare DNS records from IngressRoute annotations |
| reloader | reloader | Rolling restarts on ConfigMap/Secret changes |
| headlamp | headlamp | Kubernetes dashboard |
| homepage | homepage | Service dashboard |
| ntfy | ntfy | Push notification server |
| gatus | gatus | Uptime monitoring; alerts via ntfy |
| mealie | mealie | Self-hosted recipe manager |
| garage | garage | S3-compatible object storage |
| volsync + config | volsync-system | PVC backup operator |

### GitOps Directory Structure

```
kube-gitops/
├── k8s/                            # Bare-metal homelab cluster
│   ├── root.yaml                   # Bootstrap Application — applied once by Ansible
│   ├── apps/                       # ArgoCD watches this directory (app-of-apps)
│   ├── values/                     # Helm values per app
│   ├── cert-manager/               # ClusterIssuer + Certificate + SealedSecret
│   ├── cloudflared/                # Tunnel deployment + config + SealedSecret
│   ├── external-dns/               # SealedSecret (Cloudflare token)
│   ├── ingressroutes/              # IngressRoute + Certificate per service
│   ├── ntfy/                       # Raw manifests
│   ├── gatus/                      # SealedSecrets for alerting
│   ├── mealie/                     # Raw manifests
│   ├── garage/                     # Raw manifests
│   └── volsync-config/             # VolumeSnapshotClass
└── k3s/                            # Local dev cluster
    ├── root.yaml
    ├── apps/
    ├── values/
    ├── cert-manager/
    └── ingressroutes/
```

### Adding a New Service

1. Add an ArgoCD Application to `kube-gitops/k8s/apps/`
2. Add Helm values to `kube-gitops/k8s/values/` if needed
3. Add an IngressRoute + Certificate to `kube-gitops/k8s/ingressroutes/` with the tunnel annotation:

```yaml
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/target: "<tunnel-id>.cfargotunnel.com"
spec:
  entryPoints: [websecure]
  routes:
    - match: Host(`myapp.<your-domain.tld>`)
      services:
        - name: myapp
          port: 80
  tls:
    secretName: myapp-tls
```

4. Commit and push → ArgoCD syncs, external-dns creates the Cloudflare DNS record automatically (~1 min).

---

## Prerequisites

- 4 hosts running Debian 13, reachable via SSH
- Local workstation with Ansible installed (`local-core.yml` + `local-kube.yml`)
- `inventory/hosts` filled in with real node IPs/hostnames
- `secrets.yml` filled in (see `secrets.yml.example`)
- Cloudflare account managing your domain (for cert-manager DNS-01 + cloudflared)
- MikroTik router accessible (for DNS automation via `configure-router.yml`)

---

## Inventory Setup

```
inventory/
├── hosts                          # Node IPs and hostnames (committed)
└── group_vars/
    ├── all/
    │   ├── all.yml                # Kubespray cluster-wide settings
    │   ├── vars.yml               # Non-sensitive infra values (committed)
    │   ├── secrets.yml            # gitignored — copy from secrets.yml.example
    │   └── secrets.yml.example
    ├── kube.yml                   # Feature flags for remote hosts
    ├── local.yml                  # Feature flags for localhost (vaulted values)
    └── k8s_cluster/               # Kubespray network and addon config
```

Key variables split across `vars.yml` (committed) and `secrets.yml` (gitignored):

| Variable | File | Description |
|----------|------|-------------|
| `domain_name` | `vars.yml` | Base domain |
| `kube_vip_address` | `vars.yml` | VIP for the Kubernetes API load balancer |
| `kube_vip_interface` | `vars.yml` | Network interface for kube-vip |
| `kube_control_plane_host` | `vars.yml` | Short SSH hostname of a control plane node |
| `k8s_traefik_ip` | `vars.yml` | Traefik LoadBalancer IP |
| `mikrotik_host` | `vars.yml` | Router IP for DNS automation |
| `acme_email` | `secrets.yml` | Email for Let's Encrypt registration |
| `ansible_ssh_user` / `admin_user` | `secrets.yml` | SSH login user |
| `mikrotik_user` / `mikrotik_password` | `secrets.yml` | Router API credentials |

---

## Deployment Sequence

### First-time cluster build

```bash
# 1. Configure router DNS — must run BEFORE k8s.yml
#    api.k8s.<domain> must resolve to kube-vip before kubeadm init
ansible-playbook playbooks/configure-router.yml

# 2. SSH hardening + passwordless sudo on all nodes
#    (--ask-become-pass required here only — sudo not yet configured)
ansible-playbook --ask-become-pass playbooks/prerequisite.yml

# 3. Full node setup (shell tools, banners, fonts, network tools)
ansible-playbook playbooks/k8s-nodes.yml

# 4. Pre-cluster node preparation (etckeeper)
ansible-playbook playbooks/pre-k8s.yml

# 5. Install Kubernetes cluster via Kubespray (~21 min)
ansible-playbook -b playbooks/k8s.yml

# 6. Post-cluster: Longhorn, Traefik, Sealed Secrets, Headlamp, ArgoCD bootstrap (~2 min)
ansible-playbook playbooks/post-k8s.yml
```

After `post-k8s.yml`, ArgoCD is running and syncing the full app stack from `kube-gitops/k8s/`.

### Maintenance

```bash
# OS package upgrades on all nodes
ansible-playbook playbooks/upgrade.yml

# Tear down cluster (destructive)
ansible-playbook playbooks/reset-k8s.yml
```

### Running specific roles via tags

```bash
ansible-playbook --ask-become-pass -t ssh,sudo playbooks/prerequisite.yml
ansible-playbook -t hosts,banner,fonts playbooks/k8s-nodes.yml
ansible-playbook -t update playbooks/k8s-nodes.yml
```

**k8s-nodes.yml tags:** `update`, `ssh`, `hosts`, `banner`, `fonts`, `omp`, `fzf`, `gitconfig`, `hibernation`

---

## Rebuild Runbook

Typical timing (4-node: 3 CP + 1 worker, Kubespray 2.31 + Cilium 1.18.5):
`reset-k8s.yml` ~4 min | `k8s.yml` ~21 min | `post-k8s.yml` ~2 min | **Total ~27 min**

```bash
# 1. Ensure DNS resolves before kubeadm
ansible-playbook playbooks/configure-router.yml

# 2. Reset cluster
ansible-playbook playbooks/reset-k8s.yml

# 3. Install cluster
ansible-playbook -b playbooks/k8s.yml

# 4. Post-install (patches ArgoCD insecure mode automatically)
ansible-playbook playbooks/post-k8s.yml

# 5. Restore Sealed Secrets encryption key
kubectl apply -f ~/sealed-secrets-key-backup.yaml
kubectl rollout restart deployment sealed-secrets -n sealed-secrets
#    ArgoCD reconciles; any ContainerCreating pods waiting for SealedSecrets
#    to decrypt may need: kubectl rollout restart deployment <name> -n <ns>

# 6. Clear Firefox HSTS cache
#    Delete SiteSecurityServiceState.bin from Firefox profile folder
#    (about:support → Open Profile Folder) after a rebuild to clear stale HSTS state
```

---

## TLS / Certificate Management

cert-manager handles all certificate lifecycle via DNS-01 challenge against the Cloudflare API.
HTTP-01 is not viable — the cluster is LAN-only and not reachable from the internet.

```
cert-manager  →  Cloudflare API (DNS-01)  →  Let's Encrypt
     ↓
Per-service cert: argocd.<your-domain.tld>, headlamp.<your-domain.tld>, etc.
     ↓
Secret in each app namespace → IngressRoute tls.secretName → TLS served by Traefik
```

Per-service certs (not a wildcard) prevent HTTP/2 connection coalescing across services,
which caused browser routing issues with a shared wildcard cert.

Cloudflare API token (scoped minimally):
```
Zone → Zone → Read
Zone → DNS  → Edit
Scope: <your-domain.tld> only
```

Stored as a Sealed Secret in `kube-gitops/k8s/cert-manager/`.

---

## Sealed Secrets Workflow

```bash
# Encrypt a secret (always seal against admin@k8s, not admin@k3s)
kubectl create secret generic my-secret --namespace my-ns \
  --from-literal=KEY=value --dry-run=client -o yaml | \
  kubeseal --format yaml \
    --context "admin@k8s" \
    --controller-name sealed-secrets \
    --controller-namespace sealed-secrets \
  > kube-gitops/k8s/myapp/my-secret-sealed.yaml

# Add yamllint disable-line comment before long encrypted data lines
# Commit — the controller decrypts in-cluster, plaintext never leaves the machine
```

Sealed Secrets are cluster-specific. The k8s and k3s clusters each need their own
sealed version of any shared secret.

---

## Cloudflare Tunnel Setup

Cloudflare Tunnel exposes services to the internet without opening router ports
or exposing the home IP. `cloudflared` makes an outbound-only connection; all
inbound traffic flows through it.

### One-time setup (per cluster)

```bash
# 1. Authenticate cloudflared
cloudflared tunnel login
# Opens a browser — select the zone (<your-domain.tld>)
# Saves cert to ~/.cloudflared/cert.pem

# 2. Create the tunnel
cloudflared tunnel create k8s-homelab
# Note the tunnel ID (format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
# Credentials saved to ~/.cloudflared/<tunnel-id>.json — never commit this file

# 3. Seal the credentials for the cluster
kubectl create secret generic cloudflare-tunnel-credentials \
  -n cloudflared \
  --from-file=credentials.json=$HOME/.cloudflared/<tunnel-id>.json \
  --dry-run=client -o yaml | \
  kubeseal \
    --context admin@k8s \
    --controller-name sealed-secrets \
    --controller-namespace sealed-secrets \
    --namespace cloudflared \
    --name cloudflare-tunnel-credentials \
    -o yaml > kube-gitops/k8s/cloudflared/cloudflare-tunnel-credentials-sealed.yaml

# Add yamllint disable comment for the long encrypted line
sed -i '/credentials.json:/{i\    # yamllint disable-line rule:line-length
}' kube-gitops/k8s/cloudflared/cloudflare-tunnel-credentials-sealed.yaml

# 4. Commit and push — ArgoCD deploys cloudflared automatically
git add kube-gitops/k8s/cloudflared/cloudflare-tunnel-credentials-sealed.yaml
git commit -m "chore: add cloudflared tunnel credentials (sealed)"
git push
```

DNS records for each service are created automatically by external-dns from the
`external-dns.alpha.kubernetes.io/target` annotation on IngressRoutes.

### Verify the tunnel

```bash
kubectl get pods -n cloudflared --context admin@k8s
kubectl logs -n cloudflared --context admin@k8s -l app=cloudflared --tail=20
```

A healthy tunnel shows two connections registered (one per replica):
```
INF Connection <uuid> registered connIndex=0 ...
INF Connection <uuid> registered connIndex=1 ...
```

### Credentials rotation

```bash
# 1. Delete the old tunnel
cloudflared tunnel delete k8s-homelab

# 2. Recreate (new tunnel ID — DNS CNAME records update automatically via external-dns)
cloudflared tunnel create k8s-homelab

# 3. Re-seal new credentials (step 3 above)
# 4. Update tunnel ID in kube-gitops/k8s/cloudflared/config.yaml
# 5. Commit and push
```

---

## VolSync Backup Architecture

PVC backups run nightly via VolSync → Restic REST server on `hppd600g6`:

| PVC | Schedule | Destination |
|-----|----------|-------------|
| ntfy/ntfy-data | 02:00 daily | `rest:http://192.168.1.52:8000/ntfy` |
| gatus/gatus | 03:00 daily | `rest:http://192.168.1.52:8000/gatus` |
| mealie/mealie-data | 04:00 daily | `rest:http://192.168.1.52:8000/mealie` |

Retention: 6 hourly, 7 daily, 4 weekly, 3 monthly. Prune every 14 days.
Restic credentials stored as SealedSecrets per namespace (`volsync-restic-secret`).

DNS alias: `backups.kinet.local` → `192.168.1.52`
