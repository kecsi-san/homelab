---
title: "Homelab App Candidates"
type: research
status: stable
scope: [general]
created: 2026-05-08
updated: 2026-05-15
tags: [apps, homelab, shortlist]
---

# Homelab App Candidates

Shortlist of apps to consider adding. Distilled from `homelab-research.md` (survey of 31 repos, Round 1 + Round 2).

**Current stack** (deployed on k8s + k3s): Traefik, ArgoCD, cert-manager, Sealed Secrets, Reloader, Headlamp, Homepage, Longhorn, cloudflared, external-dns, Hubble (k8s).

---

## Priority 1 — High value, common, low risk

| App | What it does | Effort | Needs |
|-----|-------------|--------|-------|
| **kube-prometheus-stack** | Prometheus + Grafana + Alertmanager + node-exporter. Biggest gap in current stack. 8/13 Round 1 repos. | Low | Longhorn PVC |
| **VictoriaMetrics stack** | Drop-in Prometheus replacement. ~50% lower RAM than kube-prometheus-stack. `victoria-metrics-k8s-stack` chart bundles operator + Grafana. | Low | Longhorn PVC |
| **Gatus** | Endpoint uptime monitor, config-as-code YAML, generates public status page. ~30 MB RAM. 5/13 repos. | Very low | — |
| **ntfy** | Self-hosted push notifications. Alert sink for Gatus, Alertmanager, scripts. | Very low | — |
| **VolSync** | Incremental PVC backups via Restic to S3/NFS. Works with Longhorn VolumeSnapshots. Near-universal in active repos. | Medium | S3 target (see below) |

> **S3 target for VolSync:** Community has moved away from MinIO (AGPLv3 relicensed 2025, GUI removed). **Garage** (Rust, MIT, ~50 MB binary) is the current favourite for self-hosted S3. Backblaze B2 is the popular cheap cloud option.

---

## Priority 2 — High value, moderate complexity

| App | What it does | Effort | Needs |
|-----|-------------|--------|-------|
| **CloudNativePG (CNPG)** | PostgreSQL operator. HA, failover, Barman WAL archiving. Prerequisite for Immich, Authentik, Paperless-ngx. 6/13 repos. | Medium | VolSync for DB backups |
| **Vaultwarden** | Self-hosted Bitwarden. ~50 MB RAM, Rust. Also serves as ESO backend to replace Sealed Secrets. | Very low | Longhorn PVC |
| **Authentik** | Full SSO/IdP. OIDC + SAML + forward-auth for Traefik. Protects all dashboards. 5/13 repos. | Medium | CNPG, Redis/Dragonfly |
| **Authelia** | Lighter forward-auth alternative. 2FA, basic OIDC. Simpler than Authentik. | Low | Redis or file backend |
| **Immich** | Self-hosted Google Photos. Face detection, smart albums, mobile backup. Fastest-growing homelab app (7/13 repos). | Medium | CNPG, Redis/Dragonfly, storage |

---

## Priority 3 — Useful, situational

| App | What it does | Effort | Needs |
|-----|-------------|--------|-------|
| **Paperless-ngx** | Document scanner + OCR archive. Full-text search over scanned PDFs. | Low | CNPG |
| **Jellyfin** | Open-source media server. No phone-home, no cost. Dominant in community (9/18 Round 2 repos). | Low | NAS/NFS for media |
| **AdGuard Home** | DNS-level ad/tracker blocking. Replacing Pi-hole in newer setups. | Very low | — |
| **Coroot** | eBPF-based APM. Zero instrumentation — surfaces RED metrics per service automatically. Pairs with VictoriaMetrics. | Low | VictoriaMetrics |
| **Mealie** | Self-hosted recipe manager with meal planning. Low resource. | Very low | — |
| **Vikunja** | Self-hosted task/project manager (Todoist alternative). | Very low | CNPG or SQLite |
| **Actual Budget** | Personal finance / budgeting. Local-first, no cloud required. | Very low | — |

---

## Priority 4 — Nice to have, lower urgency

| App | What it does | Effort | Notes |
|-----|-------------|--------|-------|
| **Sonarr + Radarr + Prowlarr** | TV/movie library management + automated download. | Low | Jellyfin + qBittorrent |
| **qBittorrent + Gluetun** | Torrent client behind VPN sidecar. | Low | VPN subscription |
| **Home Assistant** | Home automation hub. Best on a dedicated VM (USB device access). | Medium | Separate VM recommended |
| **Miniflux** | Minimalist RSS reader. Postgres-backed. | Very low | CNPG |
| **Searxng** | Self-hosted metasearch (private Google alternative). | Very low | — |
| **n8n** | Workflow automation (self-hosted Zapier). | Low | CNPG or SQLite |
| **IT-Tools** | Browser-based developer utilities (hash, encode, diff, format). | Very low | — |
| **Nextcloud** | File sync + calendar + contacts. Heavy but comprehensive. | High | CNPG, Redis, NFS |
| **Music Assistant** | Multi-provider music player (Spotify, Tidal, local files). | Very low | — |
| **Ollama + Open WebUI** | Local LLM inference + ChatGPT-style frontend. CPU-only is slow for 7B+ models. | Low | GPU recommended |

---

## Platform upgrades (requires planning)

| Upgrade | What changes | When |
|---------|-------------|------|
| **Migrate Sealed Secrets → ESO + Vaultwarden** | Secrets pulled from Vaultwarden via External Secrets Operator. Auto-rotation, no re-sealing needed. | After Vaultwarden is stable |
| **Cilium LB-IPAM** | Replace kube-vip service LB with Cilium's native LB-IPAM. kube-vip stays for API VIP only. | Next cluster rebuild |
| **Cilium BGP control plane** | Advertise LoadBalancer IPs to router via BGP instead of L2 ARP. Eliminates MetalLB entirely. Requires BGP-capable router (MikroTik supports it). | After Cilium LB-IPAM is stable |
| **Spegel** | P2P in-cluster OCI image mirror. Reduces Docker Hub pull load on multi-node. GA in k3s since Dec 2024. | Low priority |
| **System Upgrade Controller** | Declarative k3s/node OS upgrades driven by Renovate PRs. | When node upgrades become tedious |
| **Grafana Alloy** | Replaces Grafana Agent (deprecated early 2024). OpenTelemetry-compatible collector for metrics + logs. | When adding monitoring stack |
| **Envoy Gateway** | Gateway API replacement for Traefik. `onedr0p/cluster-template` default since 2025. ingress-nginx EOL March 2026 (not relevant — we use Traefik). | Low priority for now |

---

## Recommended deploy order

1. **kube-prometheus-stack** or **VictoriaMetrics** — visibility first; pick VictoriaMetrics if RAM is a concern
2. **Gatus** + **ntfy** — status page + alerting sink
3. **VolSync** + **Garage** — backup before adding stateful apps
4. **CloudNativePG** — database operator prerequisite
5. **Vaultwarden** — password manager; enables ESO migration later
6. **Authentik** or **Authelia** — SSO before exposing more services
7. **Immich** — photo management
8. **Paperless-ngx** — document archive
9. **Jellyfin** + arr stack — media (if desired)

---

## Useful discovery tools

- **[kubesearch.dev](https://kubesearch.dev/)** — search real-world `values.yaml` across hundreds of homelab repos. Best way to find working Helm config for any chart.
- **[home-operations/containers](https://github.com/home-operations/containers)** — community container images with Renovate-compatible semver tags, for upstreams that don't publish them.

---

*Sources: `docs/homelab-research.md` — survey of 31 repos including khuedoan/homelab, onedr0p/home-ops, bjw-s-labs/home-ops, ricsanfre/pi-cluster, vehagn/homelab, techno-tim/k3s-ansible and 25 others.*
