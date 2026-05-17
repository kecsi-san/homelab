---
title: "012 — Cloudflare Tunnel + WARP for External Access"
type: adr
status: accepted
scope: [k8s]
created: 2026-05-10
updated: 2026-05-17
tags: [cloudflare, tunnel, warp, networking, remote-access, tls]
---

# 012 — Cloudflare Tunnel + WARP for External Access

## Status

Accepted

## Context

Homelab services run behind a home router with a dynamic residential ISP IP address.
External access (from outside the LAN) requires either:
1. A static IP / DDNS with port forwarding (opens ports on the home router)
2. A tunneling service that establishes an outbound connection from the cluster

Port forwarding on a residential connection exposes the home IP directly to the internet,
requires firewall management, and is blocked by some ISPs. A tunneling approach avoids
all of these issues.

Additionally, a client-side VPN (Cloudflare WARP) allows laptops/phones outside the
LAN to reach homelab services with the same URLs and TLS certificates as on the LAN.

Requirements:
- No inbound port forwarding on the home router
- No static IP required (dynamic ISP IP is fine)
- All services accessible via `*.kecskemethy.org` regardless of client location
- TLS encryption in transit (browser sees a valid HTTPS certificate)
- Compatible with Traefik as the in-cluster ingress controller
- Minimal operational maintenance once set up

## Decision

Use **Cloudflare Tunnel** (`cloudflared`) for inbound tunnel from Cloudflare edge to
the cluster, combined with **Cloudflare WARP** on client devices for the VPN path:

**Tunnel architecture:**
- `cloudflared` pod runs in the `cloudflared` namespace; deployed as ArgoCD app
- Tunnel established from `cloudflared` pod → Cloudflare edge (outbound-only; no
  inbound ports opened on the home router)
- Cloudflare DNS: `*.kecskemethy.org` → Cloudflare Tunnel (CNAME to `<uuid>.cfargotunnel.com`)
- Traffic path: Browser → Cloudflare Edge → Cloudflare Tunnel → `cloudflared` pod →
  `https://traefik.traefik.svc.cluster.local` → Traefik → in-cluster service
- `noTLSVerify: true` on the `cloudflared` → Traefik connection (Traefik presents
  a LAN certificate; Cloudflare does not verify it)
- Cloudflare terminates TLS for the client; Cloudflare Universal SSL cert is what
  browsers see on the Cloudflare path

**WARP architecture:**
- Cloudflare WARP installed on client devices (laptop, phone)
- WARP routes traffic through Cloudflare's network; homelab services appear reachable
  as if the client were at the Cloudflare edge
- On-LAN: MikroTik wildcard DNS `*.kecskemethy.org` → 192.168.1.101 (Traefik directly)
- Off-LAN with WARP: browser → WARP → Cloudflare → Tunnel → cluster (same URL, same cert)

**Dual TLS path:**
| Path | DNS resolves to | TLS cert | TLS terminated at |
|------|----------------|----------|-------------------|
| LAN (no WARP, Edge browser) | 192.168.1.101 (Traefik directly) | cert-manager Let's Encrypt per-service cert | Traefik |
| Cloudflare WARP / external | Cloudflare Tunnel | Cloudflare Universal SSL | Cloudflare edge |

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| **Port forwarding + DDNS** | Exposes home IP directly; requires firewall rules per service; ISP may block port 443; dynamic IP updates add complexity; no CDN/DDoS protection |
| **Tailscale** | Excellent WireGuard-based mesh VPN; no tunnel needed; however, requires installing Tailscale on every client and every cluster node; not suitable for browser-only access by guests; adds Tailscale dependency |
| **WireGuard (self-hosted)** | Full control; however, requires a static IP or DDNS endpoint for the WireGuard server; running WireGuard in k8s adds networking complexity; client config management is manual |
| **Cloudflare Access (Zero Trust)** | Cloudflare's identity-aware proxy; adds Cloudflare Access policy on top of the tunnel; however, adds another authentication layer (Cloudflare login before reaching Authentik); the homelab already has Authentik for SSO — double authentication is poor UX |
| **ngrok** | Simple tunnel but rate-limited on free tier; paid plans required for custom domains; not k8s-native; less control than `cloudflared` |
| **SSH tunnels / sshuttle** | Manual, fragile, not persistent; not suitable for production-like homelab services |

## Consequences

**Positive:**
- Zero inbound ports on the home router — the attack surface is minimal; `cloudflared`
  only makes outbound connections
- Services reachable from anywhere via WARP with no client configuration beyond
  installing the WARP app; the same `*.kecskemethy.org` URLs work on-LAN and off-LAN
- Cloudflare provides DDoS mitigation and bot protection at the edge for free
- `cloudflared` pod restarts automatically if the tunnel drops; Cloudflare's HA tunnel
  feature (multiple `cloudflared` replicas connecting to the same tunnel) provides
  redundancy

**Negative / Trade-offs:**
- **Dual TLS paths create inconsistency**: LAN clients see a cert-manager-issued
  Let's Encrypt cert; WARP/external clients see Cloudflare Universal SSL. The
  certificate CN is different; HSTS state in browsers can cause confusion after switching
  paths — notably Firefox caches HSTS entries and after cluster rebuilds (new LE certs)
  shows SSL errors until `SiteSecurityServiceState.bin` is deleted from the Firefox
  profile
- **`noTLSVerify: true`**: The segment from `cloudflared` to Traefik skips TLS
  verification; this is acceptable since both are inside the cluster on the cluster
  network, but it means a compromised cluster pod could theoretically MITM this segment
- **Cloudflare as a dependency**: external access requires Cloudflare to be operational;
  if Cloudflare has an outage, external access is lost (LAN access via MikroTik DNS is
  unaffected)
- **All external traffic transits Cloudflare**: Cloudflare can see unencrypted HTTP
  traffic between the edge and `cloudflared` (since `noTLSVerify: true`); this is
  acceptable for a personal homelab but would not be appropriate for sensitive enterprise
  data
- Cloudflare Tunnel token stored as a SealedSecret; must be re-sealed after cluster
  rebuild (same key backup discipline as all other SealedSecrets)
