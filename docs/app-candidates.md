# Homelab App Candidates

Shortlist of apps to consider adding. Distilled from `homelab-research.md` (survey of 13 popular homelab repos).

**Current stack** (already deployed on k8s + k3s): Traefik, ArgoCD, cert-manager, Sealed Secrets, Reloader, Headlamp, Homepage, Longhorn, cloudflared, external-dns.

---

## Priority 1 — High value, common, low risk

| App | What it does | Effort | Needs |
|-----|-------------|--------|-------|
| **kube-prometheus-stack** | Prometheus + Grafana + Alertmanager + node-exporter in one Helm chart. Biggest gap in current stack. | Low | persistent storage (Longhorn) |
| **Gatus** | Endpoint uptime monitor, config-as-code YAML, generates status page. ~30 MB RAM. | Very low | — |
| **VolSync** | Incremental PVC backups to S3/NFS using Restic. Works with Longhorn snapshots. | Medium | S3 bucket (Backblaze B2) or NFS |

---

## Priority 2 — High value, moderate complexity

| App | What it does | Effort | Needs |
|-----|-------------|--------|-------|
| **CloudNativePG (CNPG)** | PostgreSQL operator. HA, failover, WAL archiving. Prerequisite for Immich, Authentik, Paperless-ngx. | Medium | VolSync for DB backups |
| **Authentik** | SSO / forward-auth for Traefik. OIDC + SAML. Protects all internal dashboards with single login. | Medium | CNPG (Postgres), Redis |
| **Authelia** | Lighter alternative to Authentik. Forward-auth only (no OIDC). Simpler setup. | Low | Redis or file backend |
| **Immich** | Self-hosted Google Photos. Face detection, smart albums, mobile backup app. Fastest-growing homelab app. | Medium | CNPG, Redis/Dragonfly, storage |

---

## Priority 3 — Useful, situational

| App | What it does | Effort | Needs |
|-----|-------------|--------|-------|
| **Paperless-ngx** | Document scanner + OCR archive. Ingests PDFs/scans, full-text search. | Low | CNPG (Postgres) |
| **Vaultwarden** | Self-hosted Bitwarden password manager. Very low resource usage (~50 MB). | Very low | persistent storage |
| **ntfy** | Push notification server. Used for alerts from Gatus, scripts, Alertmanager. | Very low | — |
| **Jellyfin** | Open-source media server (Plex alternative). No phone-home, no cost. | Low | NAS/NFS for media |
| **AdGuard Home** | DNS-level ad/tracker blocking. Replaces Pi-hole. | Very low | — |

---

## Priority 4 — Nice to have, lower urgency

| App | What it does | Effort | Notes |
|-----|-------------|--------|-------|
| **Sonarr + Radarr + Prowlarr** | TV/movie library management + download automation. | Low | Jellyfin prerequisite |
| **qBittorrent + Gluetun** | Torrent client behind VPN. | Low | VPN subscription |
| **Nextcloud** | File sync + calendar + contacts. Heavy but comprehensive. | High | CNPG, Redis, NFS |
| **Home Assistant** | Home automation hub. Best run on a VM (USB device access). | Medium | Separate VM recommended |
| **Miniflux** | Minimalist RSS reader. | Very low | CNPG (Postgres) |
| **Searxng** | Self-hosted metasearch engine (private Google alternative). | Very low | — |
| **n8n** | Workflow automation (self-hosted Zapier). | Low | CNPG or SQLite |
| **IT-Tools** | Browser-based developer utilities (hash, encode, format). | Very low | — |

---

## Platform upgrades (requires planning)

| Upgrade | What changes | When |
|---------|-------------|------|
| **Migrate Sealed Secrets → External Secrets Operator** | Secrets pulled from 1Password or Vaultwarden; auto-rotation support. 8/13 repos use ESO. | After Vaultwarden is stable |
| **Cilium LB-IPAM** | Replace kube-vip service LB with Cilium's built-in LB. kube-vip stays for API VIP. | Next cluster rebuild |
| **Spegel** | P2P in-cluster image mirror. Reduces Docker Hub pulls on multi-node clusters. | Low priority |
| **System Upgrade Controller** | Declarative k3s/node OS upgrades, driven by Renovate PRs. | When node upgrades become tedious |

---

## Recommended deploy order (if starting from scratch)

1. kube-prometheus-stack — visibility first
2. Gatus — status page
3. ntfy — alerting sink
4. VolSync — backup before adding stateful apps
5. CloudNativePG — database operator
6. Vaultwarden — password manager (also useful as ESO backend)
7. Authentik or Authelia — SSO before exposing more services
8. Immich — photo management
9. Paperless-ngx — document archive
10. Jellyfin + arr stack — media (if desired)

---

*Source: `docs/homelab-research.md` — survey of 13 repos including khuedoan/homelab, onedr0p/home-ops, bjw-s-labs/home-ops.*
