---
title: "Workflow: Local k3s Cluster (WSL2 / macOS)"
type: how-to
status: stable
scope: [k3s, ansible]
created: 2026-05-10
updated: 2026-05-15
tags: [k3s, wsl2, macos, ansible, setup]
---

# Workflow: Local k3s Cluster (WSL2 / macOS)

Single-node Kubernetes cluster on localhost for local development and GitOps experimentation.
No remote inventory or SSH required — everything targets `127.0.0.1`.

| Platform | Implementation |
|----------|---------------|
| Linux (WSL2) | Native k3s via official installer (`get.k3s.io`) |
| macOS | k3s via k3d (k3s in Docker) via Homebrew — requires Colima, Docker Desktop, or OrbStack |

Kubeconfig is written to `~/.kube/k3s.yaml`, appended to `KUBECONFIG` in `~/.bashrc`, and the context is automatically renamed to `admin@k3s`.

---

## Prerequisites

- Local workstation setup complete (`local-core.yml` + `local-kube.yml`)
- `secrets.yml` filled in (see `secrets.yml.example`)
- macOS only: Colima or Docker Desktop running

---

## Install

```bash
# 1. Install k3s (native on WSL2, k3d on macOS)
ansible-playbook playbooks/k3s.yml

# 2. Bootstrap GitOps — installs ArgoCD, then ArgoCD manages everything else
#    (Traefik, Sealed Secrets, Headlamp, cert-manager via kube-gitops/k3s/)
ansible-playbook playbooks/post-k3s.yml
```

After `post-k3s.yml` completes, ArgoCD is running and will automatically sync the
app-of-apps from `kube-gitops/k3s/`. All further changes are GitOps-driven.

## Uninstall

```bash
ansible-playbook playbooks/reset-k3s.yml
```

---

## WSL2 Networking Quirks

Running k3s inside WSL2 with `networkingMode=Mirrored` has several non-obvious
differences from a standard Linux cluster. All the solutions below are already
applied in `kube-gitops/k3s/values/traefik.yaml`.

**Environment assumed:** WSL2 (Debian), `networkingMode=Mirrored` in `~/.wslconfig`,
Windows 11, WSL2 node IP `192.168.1.25` directly on the LAN.

### Problem 1 — k3s servicelb uses DNAT, not real listeners

k3s's built-in load balancer (`servicelb`) creates nftables DNAT rules to forward
ports — no process ever binds to port 80 or 443 on the host. WSL2 mirrored mode
only forwards traffic for ports with a real `listen()` socket, so DNAT-based ports
are invisible to Windows and other LAN devices.

**Symptom:**
```powershell
Test-NetConnection -ComputerName 192.168.1.25 -Port 443
# TcpTestSucceeded : False  ← even though Traefik is "running"
```

**Solution:** Run Traefik with `hostNetwork: true` and `service.type: ClusterIP`.
Traefik binds directly to host ports 80/443, creating real listeners.

**Verify:**
```bash
ss -tlnp | grep -E ":80 |:443 "
# LISTEN 0  4096  *:443  *:*
# LISTEN 0  4096  *:80   *:*
```

### Problem 2 — Rolling updates impossible with hostNetwork on single node

With `hostNetwork: true`, a rolling update tries to start the new pod before killing
the old one — both pods declare the same host ports, so the new pod stays `Pending`:

```
0/1 nodes are available: 1 node(s) didn't have free ports for the requested pod ports.
```

**Solution:** `updateStrategy.type: Recreate` — terminates old pod first. Brief
downtime is acceptable for a LAN-only dev cluster.

If ArgoCD syncs a change and a pod gets stuck `Pending`, unblock it:
```bash
kubectl delete pod -n traefik --all
```

### Problem 3 — Metrics port 9100 conflicts with node-exporter

Traefik's default metrics port (`9100`) conflicts with `prometheus-node-exporter`
already running on the WSL2 host.

**Solution:** `ports.metrics.port: 9101` in Traefik values.

### Problem 4 — NET_BIND_SERVICE not honoured for non-root on WSL2

Traefik runs non-root by default. `NET_BIND_SERVICE` capability (needed to bind
ports < 1024) is not honoured by WSL2's kernel for non-root containers.

**Symptom:**
```
ERR Command error  error="listen tcp :80: bind: permission denied"
```

**Solution:** Override pod security context to run as root. Acceptable for a
LAN-only dev cluster.

```yaml
podSecurityContext:
  runAsUser: 0
  runAsNonRoot: false
  runAsGroup: 0
```

### Problem 5 — Windows cannot reach WSL2 via its own LAN IP

Even with all fixes above, `homepage.k3s.<your-domain.tld>` fails in Firefox on
the Windows host. Other LAN devices (phone, other laptops) work fine.

**Root cause:** When Windows connects to `192.168.1.25` (its own LAN IP), the
packet never enters WSL2's network namespace — Windows handles it internally.
`localhost` / `127.0.0.1` works because WSL2 mirrored mode explicitly handles the
loopback path.

**Solution:** Add entries to `C:\Windows\System32\drivers\etc\hosts` (as Administrator):

```
127.0.0.1 homepage.k3s.<your-domain.tld>
127.0.0.1 argocd.k3s.<your-domain.tld>
127.0.0.1 headlamp.k3s.<your-domain.tld>
127.0.0.1 traefik.k3s.<your-domain.tld>
```

MikroTik DNS continues to return `192.168.1.25` for all other LAN devices.
The Windows hosts file overrides only the local machine.

**Verify hosts file is applied** (`nslookup` bypasses it — use `ping` or `Resolve-DnsName`):
```powershell
ping -n 1 homepage.k3s.<your-domain.tld>
# Reply from 127.0.0.1  ← correct

Resolve-DnsName homepage.k3s.<your-domain.tld>
# IPAddress: 127.0.0.1  ← correct
```

After adding entries, clear Firefox's DNS cache at `about:networking#dns`.

---

## DNS Setup Summary

| Client | DNS result | Reaches |
|--------|-----------|---------|
| Other LAN devices | MikroTik wildcard `*.k3s.<your-domain.tld>` → `192.168.1.25` | WSL2 via LAN |
| Windows host | hosts file `127.0.0.1` | WSL2 via loopback |

MikroTik wildcard entry (managed by `configure-router.yml`):
```
*.k3s.<your-domain.tld>  →  192.168.1.25
```
This is more specific than `*.<your-domain.tld> → 192.168.1.101` so it takes priority.

---

## Debugging Checklist

```bash
# 1. Are real listeners present on the host?
ss -tlnp | grep -E ":80 |:443 "

# 2. Does Traefik respond from within WSL2?
curl -sk -o /dev/null -w "%{http_code}" -H "Host: homepage.k3s.<your-domain.tld>" https://127.0.0.1/

# 3. Reachable from another LAN device?
ssh hped800g5 "curl -sk --resolve 'homepage.k3s.<your-domain.tld>:443:192.168.1.25' \
  -o /dev/null -w '%{http_code}' https://homepage.k3s.<your-domain.tld>/"
```

```powershell
# 4. Windows DNS sees 127.0.0.1?
ping -n 1 homepage.k3s.<your-domain.tld>
Resolve-DnsName homepage.k3s.<your-domain.tld>

# 5. Firefox DNS cache stale? Clear at about:networking#dns
```
