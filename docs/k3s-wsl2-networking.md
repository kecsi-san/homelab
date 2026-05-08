# k3s on WSL2 — Networking Quirks and Solutions

This document covers the non-obvious differences when running k3s inside WSL2
with mirrored networking mode, compared to a standard Linux bare-metal cluster.

**Environment:** WSL2 (Debian), `networkingMode=Mirrored` in `.wslconfig`,
Windows 11, node IP `192.168.1.25/25` directly on the LAN.

---

## WSL2 Mirrored Networking — What It Does

With `networkingMode=Mirrored` in `~/.wslconfig`:
- WSL2 shares the same IP as the Windows host (e.g. `192.168.1.25`)
- `localhost` on Windows reaches WSL2 services that have **real socket listeners**
- Other LAN devices can reach WSL2 services if they have real socket listeners

**Critical caveat:** WSL2 mirrored mode only forwards traffic for ports where a
process has an actual `listen()` socket. iptables/nftables DNAT rules are
invisible to WSL2's forwarding mechanism — no real socket = no forwarding.

---

## Problem 1 — k3s servicelb (klipper-lb) uses DNAT, not real listeners

k3s's built-in load balancer (`servicelb`) creates a DaemonSet pod that sets up
nftables DNAT rules to forward `<nodeIP>:<port>` → `<ClusterIP>:<port>`. No
process ever binds to port 80 or 443 on the host, so `ss -tlnp` shows nothing.

WSL2 mirrored mode never sees these ports and does not forward incoming
connections from Windows or other LAN devices.

### Symptom
```
# From Windows PowerShell:
Test-NetConnection -ComputerName 192.168.1.25 -Port 443
# TcpTestSucceeded : False  ← even though Traefik is "running"
```

### Solution — Traefik hostNetwork + ClusterIP

Run Traefik with `hostNetwork: true` so it binds directly to host ports 80/443,
creating real listeners. Change service to `ClusterIP` to remove servicelb
(which would conflict).

```yaml
# kube-gitops/k3s/values/traefik.yaml
hostNetwork: true

service:
  type: ClusterIP

updateStrategy:
  type: Recreate   # see Problem 2

ports:
  web:
    port: 80
    redirections:
      entryPoint:
        to: websecure
        scheme: https
  websecure:
    port: 443
  metrics:
    port: 9101     # see Problem 3

podSecurityContext:
  runAsUser: 0     # see Problem 4
  runAsNonRoot: false
  runAsGroup: 0

securityContext:
  capabilities:
    drop: [ALL]
    add: [NET_BIND_SERVICE]
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
```

**Verification:**
```bash
ss -tlnp | grep -E ":80 |:443 "
# LISTEN 0  4096  *:443  *:*
# LISTEN 0  4096  *:80   *:*
```

---

## Problem 2 — Rolling updates impossible with hostNetwork on single node

With `hostNetwork: true`, a pod binds directly to host ports. A rolling update
tries to start the new pod before killing the old one — both pods declare the
same host ports, so the new pod is stuck `Pending`:

```
0/1 nodes are available: 1 node(s) didn't have free ports for the requested pod ports.
```

### Solution — Recreate update strategy

```yaml
updateStrategy:
  type: Recreate
```

This terminates the old pod first, then starts the new one. Brief downtime is
acceptable for a LAN-only dev cluster.

When ArgoCD syncs a change and a pod gets stuck `Pending`, force it by deleting
all Traefik pods — the Recreate deployment immediately starts the new one:

```bash
kubectl delete pod -n traefik --all
```

---

## Problem 3 — Metrics port 9100 conflicts with prometheus-node-exporter

Traefik's default metrics port is `9100`. With `hostNetwork: true`, this binds
to the host and conflicts with `prometheus-node-exporter` which is already
running on the WSL2 host on port 9100.

### Solution

```yaml
ports:
  metrics:
    port: 9101
```

---

## Problem 4 — NET_BIND_SERVICE not honoured for non-root on WSL2

Traefik's Helm chart runs the container as uid 65532 (non-root) by default.
Adding `NET_BIND_SERVICE` to `securityContext.capabilities.add` is the standard
Linux solution for non-root processes binding to ports < 1024, but WSL2's kernel
does not honour this capability for non-root containers.

### Symptom
```
ERR Command error  error="listen tcp :80: bind: permission denied"
```

### Solution

Override the pod security context to run as root. Acceptable for a LAN-only dev
cluster with no internet exposure.

```yaml
podSecurityContext:
  runAsUser: 0
  runAsNonRoot: false
  runAsGroup: 0
```

---

## Problem 5 — Windows cannot reach WSL2 via its own LAN IP

Even with all the above fixes, `homepage.k3s.kecskemethy.org` still fails in
Firefox on the Windows host. Other LAN devices (phone, other laptops) work fine.

**Root cause:** When Windows connects to `192.168.1.25` (its own LAN IP),
the packet never enters WSL2's network namespace — Windows handles it internally
before WSL2 sees it. The nftables rules and host listeners in WSL2 are bypassed.

`localhost` / `127.0.0.1` does work from Windows because WSL2 mirrored mode
explicitly handles the loopback path.

### Verification

```powershell
# Fails — routes via LAN IP, bypasses WSL2
Test-NetConnection -ComputerName 192.168.1.25 -Port 443

# Works — WSL2 mirrored mode handles loopback
Test-NetConnection -ComputerName localhost -Port 443
```

### Solution — Windows hosts file pointing to 127.0.0.1

Add entries to `C:\Windows\System32\drivers\etc\hosts` (as Administrator):

```
127.0.0.1 homepage.k3s.kecskemethy.org
127.0.0.1 argocd.k3s.kecskemethy.org
127.0.0.1 headlamp.k3s.kecskemethy.org
127.0.0.1 traefik.k3s.kecskemethy.org
```

MikroTik DNS continues to return `192.168.1.25` for all other LAN devices, which
works correctly. The Windows hosts file overrides only the local machine.

**Note:** `nslookup` bypasses the hosts file — always use `ping` or
`Resolve-DnsName` to verify hosts file entries are applied:

```powershell
ping -n 1 homepage.k3s.kecskemethy.org
# Reply from 127.0.0.1  ← correct

Resolve-DnsName homepage.k3s.kecskemethy.org
# IPAddress: 127.0.0.1  ← correct
```

### Firefox DNS cache

After adding hosts file entries, Firefox may still use its internal DNS cache.
Clear it at `about:networking#dns` → **Clear DNS Cache**.

---

## DNS setup summary

| Client | DNS result | Reaches |
|--------|-----------|---------|
| Other LAN devices | MikroTik: `192.168.1.25` | WSL2 via LAN — works |
| Windows host | hosts file: `127.0.0.1` | WSL2 via loopback — works |
| Windows `nslookup` | Always queries DNS directly — ignore | — |

### MikroTik wildcard DNS entry

```
/ip dns static add name="*.k3s.kecskemethy.org" address=192.168.1.25 ttl=5m
```

This takes priority over the existing `*.kecskemethy.org → 192.168.1.101` entry
because it is more specific.

---

## Debugging checklist

```bash
# 1. Are real listeners present on the host?
ss -tlnp | grep -E ":80 |:443 "

# 2. Does Traefik respond from within WSL2?
curl -sk -o /dev/null -w "%{http_code}" -H "Host: homepage.k3s.kecskemethy.org" https://127.0.0.1/

# 3. Is it reachable from another LAN device? (use a k8s node as proxy)
ssh hped800g5 "curl -sk --resolve 'homepage.k3s.kecskemethy.org:443:192.168.1.25' \
  -o /dev/null -w '%{http_code}' https://homepage.k3s.kecskemethy.org/"

# 4. Does Windows DNS see 127.0.0.1? (not nslookup — that bypasses hosts file)
# Run in PowerShell:
# ping -n 1 homepage.k3s.kecskemethy.org
# Resolve-DnsName homepage.k3s.kecskemethy.org

# 5. Firefox DNS cache stale? Clear at about:networking#dns
```
