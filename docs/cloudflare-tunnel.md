# Cloudflare Tunnel — Internet Access for Homelab Services

Cloudflare Tunnel exposes cluster services to the internet without opening ports on the
router or exposing the home IP. A `cloudflared` Deployment in the cluster makes an
outbound-only connection to Cloudflare's edge; all inbound traffic flows through it.

---

## Architecture

```
Internet browser
      │
      ▼
Cloudflare edge  (DNS: argocd.k8s.kecskemethy.org → <tunnel-id>.cfargotunnel.com)
      │  encrypted tunnel (outbound from cluster)
      ▼
cloudflared pod (Deployment, 2 replicas, namespace: cloudflared)
      │  https://traefik.traefik.svc.cluster.local
      ▼
Traefik  (TLS termination, wildcard cert from cert-manager)
      │  Host-header routing
      ▼
argocd-server / headlamp / longhorn-frontend
```

LAN access is unchanged — router DNS overrides resolve directly to Traefik's IP
(192.168.1.101) and bypass Cloudflare entirely.

---

## Prerequisites

- Cloudflare account managing the `kecskemethy.org` zone
- `cloudflared` CLI installed locally
- `kubeseal` CLI installed locally
- Sealed Secrets controller running in the target cluster
- Cluster reachable via `kubectl` (kubeconfig configured)

Install `cloudflared`:

```bash
brew install cloudflare/cloudflare/cloudflared
```

---

## One-time Setup (per cluster)

### 1. Authenticate cloudflared with Cloudflare

```bash
cloudflared tunnel login
```

This opens a browser. Select the zone (`kecskemethy.org`). A certificate is saved to
`~/.cloudflared/cert.pem` — this authorises the CLI to create tunnels in that zone.

### 2. Create the tunnel

```bash
cloudflared tunnel create k8s-homelab
```

Note the **tunnel ID** from the output (format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).

A credentials JSON file is written to `~/.cloudflared/<tunnel-id>.json`. This file
is the secret — it proves ownership of the tunnel. Keep it secure; never commit it.

### 3. Seal the credentials for the cluster

The credentials file is sealed with the cluster's Sealed Secrets public key — a
different seal is required per cluster since each has its own private key.

```bash
kubectl create secret generic cloudflare-tunnel-credentials \
  -n cloudflared \
  --from-file=credentials.json=$HOME/.cloudflared/<tunnel-id>.json \
  --dry-run=client -o yaml | \
kubeseal \
  --kubeconfig ~/.kube/k8s.yaml \
  --controller-name sealed-secrets \
  --controller-namespace sealed-secrets \
  --namespace cloudflared \
  --name cloudflare-tunnel-credentials \
  -o yaml > kube-gitops/k8s/cloudflared/cloudflare-tunnel-credentials-sealed.yaml
```

Add the yamllint disable comment for the long encrypted line:

```bash
sed -i '/credentials.json:/{i\    # yamllint disable-line rule:line-length
}' kube-gitops/k8s/cloudflared/cloudflare-tunnel-credentials-sealed.yaml
```

### 4. Commit and push

```bash
git add kube-gitops/k8s/cloudflared/cloudflare-tunnel-credentials-sealed.yaml
git commit -m "chore: add cloudflared tunnel credentials (sealed)"
git push
```

ArgoCD picks up the change and deploys the `cloudflared` Deployment automatically
(the ArgoCD Application is in `kube-gitops/k8s/apps/cloudflared.yaml`).

### 5. Add DNS records in Cloudflare

Either via CLI (requires `cloudflared tunnel login` to have run):

```bash
cloudflared tunnel route dns k8s-homelab argocd.k8s.kecskemethy.org
cloudflared tunnel route dns k8s-homelab headlamp.k8s.kecskemethy.org
cloudflared tunnel route dns k8s-homelab longhorn.k8s.kecskemethy.org
```

Or manually in the Cloudflare dashboard — add a CNAME record for each hostname:

| Name | Type | Target | Proxy |
|------|------|--------|-------|
| `argocd.k8s.kecskemethy.org` | CNAME | `<tunnel-id>.cfargotunnel.com` | ✅ Proxied |
| `headlamp.k8s.kecskemethy.org` | CNAME | `<tunnel-id>.cfargotunnel.com` | ✅ Proxied |
| `longhorn.k8s.kecskemethy.org` | CNAME | `<tunnel-id>.cfargotunnel.com` | ✅ Proxied |

The proxy (orange cloud) must be **on** — traffic routes through Cloudflare's edge.

---

## GitOps Resources

All resources except the sealed credentials are static and already in the repo.

| File | Purpose |
|------|---------|
| `kube-gitops/k8s/cloudflared/config.yaml` | ConfigMap with tunnel ID and ingress routing rules |
| `kube-gitops/k8s/cloudflared/deployment.yaml` | cloudflared Deployment (2 replicas) |
| `kube-gitops/k8s/cloudflared/cloudflare-tunnel-credentials-sealed.yaml` | SealedSecret (cluster-specific) |
| `kube-gitops/k8s/apps/cloudflared.yaml` | ArgoCD Application (auto-picked by root app-of-apps) |

The routing config (`config.yaml`) sends all `*.k8s.kecskemethy.org` traffic to
Traefik's HTTPS endpoint (`traefik.traefik.svc.cluster.local:443`) with
`noTLSVerify: true` — the cert CN is the wildcard domain, not the internal service
name, so hostname verification is skipped while the connection remains encrypted.

---

## Verify the tunnel

Check pods are running and connected:

```bash
kubectl get pods -n cloudflared --kubeconfig ~/.kube/k8s.yaml
kubectl logs -n cloudflared --kubeconfig ~/.kube/k8s.yaml \
  -l app=cloudflared --tail=20
```

A healthy tunnel shows:

```
INF Connection <uuid> registered connIndex=0 ...
INF Connection <uuid> registered connIndex=1 ...
```

Each replica registers its own connection. Two replicas means two independent
connections to different Cloudflare PoPs for redundancy.

Test from outside the LAN (e.g., mobile data):

```bash
curl -sv https://argocd.k8s.kecskemethy.org/ 2>&1 | grep -E "< HTTP|issuer"
```

---

## Tunnel ID reference

| Cluster | Tunnel name | Tunnel ID |
|---------|-------------|-----------|
| k8s homelab | `k8s-homelab` | `9fa18953-8d82-424d-a8b5-9941940d4230` |

---

## Credentials rotation

If the tunnel credentials file is lost or compromised:

```bash
# 1. Delete the old tunnel
cloudflared tunnel delete k8s-homelab

# 2. Recreate it (new tunnel ID — DNS records must be updated)
cloudflared tunnel create k8s-homelab

# 3. Re-seal the new credentials file (step 3 above)

# 4. Update config.yaml with the new tunnel ID

# 5. Update DNS CNAME records to point to the new tunnel ID

# 6. Commit and push
```
