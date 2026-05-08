# Homelab Kubernetes Research

Survey of popular homelab Kubernetes GitHub repositories (≥100 stars), covering what the community deploys at the platform and application layers.

---

## 1. Source Repos

| Repo | Stars | Description |
|------|-------|-------------|
| [khuedoan/homelab](https://github.com/khuedoan/homelab) | 9.2k | Fully automated homelab from bare disk to running services with a single command. PXE boot, k3s, GitOps via ArgoCD, Fedora nodes. |
| [onedr0p/home-ops](https://github.com/onedr0p/home-ops) | 2.8k | "Wife approved HomeOps". Flux, Talos, Cilium, Rook, 1Password via External Secrets. Template for the community cluster. |
| [billimek/k8s-gitops](https://github.com/billimek/k8s-gitops) | 769 | Long-running Flux-based GitOps repo; Talos, Rook-Ceph, extensive app catalog. |
| [xunholy/k8s-gitops](https://github.com/xunholy/k8s-gitops) | 630 | Educational repo demonstrating CNCF stack: Cilium, Envoy Gateway, Rook-Ceph, External Secrets, VolSync. |
| [Mafyuh/iac](https://github.com/Mafyuh/iac) | 471 | GitOps IaC for homelab: Flux Operator, Proxmox hypervisor, k3s+Talos, VictoriaMetrics/Grafana. |
| [bjw-s-labs/home-ops](https://github.com/bjw-s-labs/home-ops) | 828 | Talos, Flux, OpenEBS, kanidm for identity; curated app set (media, home automation, AI). |
| [buroa/k8s-gitops](https://github.com/buroa/k8s-gitops) | 371 | Talos on Minisforum mini-PCs, Flux, Cilium, Envoy Gateway, Rook, VolSync, 1Password ESO. |
| [szinn/k8s-homelab](https://github.com/szinn/k8s-homelab) | 294 | Talos, Flux, Rook-Ceph + NFS, ingress-nginx, CloudNativePG, VolSync backups. |
| [ahinko/home-ops](https://github.com/ahinko/home-ops) | 288 | Talos, Flux, Ansible provisioning, AdGuard DNS. Minimalist approach. |
| [toboshii/home-ops](https://github.com/toboshii/home-ops) | 385 | Talos, Cilium, Rook-Ceph, NGINX ingress, SOPS secrets, Flux, External-DNS. |
| [nicolerenee/infra](https://github.com/nicolerenee/infra) | 109 | Talos, Flux, Cilium, Rook-Ceph, CloudNativePG, VictoriaMetrics, MetalLB BGP. Emby/Jellyfin/Plex, Home Assistant/ESPHome, Authentik. |
| [lisenet/kubernetes-homelab](https://github.com/lisenet/kubernetes-homelab) | 501 | kubeadm, Calico, Democratic CSI + TrueNAS NFS, Istio, MetalLB, Velero, Prometheus/Grafana/Alertmanager. |
| [mitchross/talos-argocd-proxmox](https://github.com/mitchross/talos-argocd-proxmox) | 68 | Talos + ArgoCD + Proxmox; Longhorn + VolSync + CloudNativePG, Kyverno policies, GPU operator, KEDA. |

---

## 2. Platform Layer — What People Typically Run

### GitOps

| Tool | Repos | Notes |
|------|-------|-------|
| **Flux CD** | 10/13 | Dominant choice in community clusters. Lightweight, Git-native reconciliation. Used with Helm controller, Kustomize controller. `onedr0p/cluster-template` ships Flux as default. |
| **ArgoCD** | 3/13 | Used by khuedoan/homelab, mitchross, and this repo. Heavier UI but better App-of-Apps support. Often paired with Argo app-of-apps or ApplicationSets. |
| **Renovate** | 11/13 | Nearly universal. Automates dependency/image version PRs. Runs as a scheduled job inside the cluster or via GitHub Actions. |
| **GitHub Actions** | 8/13 | CI for lint, diff, and kubeconform checks. Often paired with `actions-runner-controller` for self-hosted runners. |

### Ingress / Gateway

| Tool | Repos | Notes |
|------|-------|-------|
| **ingress-nginx** | 5/13 | Traditional workhorse. Simple, widely documented. Used by szinn, toboshii, lisenet. |
| **Traefik** | 3/13 | Used by this repo, khuedoan (early), some Proxmox setups. Good dashboard, native Let's Encrypt integration. |
| **Envoy Gateway** | 3/13 | Growing fast. Implements Kubernetes Gateway API. Used by onedr0p, buroa, xunholy. The `onedr0p/cluster-template` defaults to Envoy Gateway as of 2024–2025. |
| **Cilium (Gateway API)** | 2/13 | Cilium itself can serve as a Gateway API implementation, eliminating a separate ingress controller. Used by mitchross and some Cilium-only setups. |

### TLS / Certificate Management

| Tool | Repos | Notes |
|------|-------|-------|
| **cert-manager** | 13/13 | Universal. Always present. Integrates with Let's Encrypt via HTTP01 or DNS01 (Cloudflare most common), and with private CAs. |
| **Cloudflare DNS01** | 9/13 | Dominant ACME challenge method for wildcard certs. Works with external-dns and cloudflared together. |
| **cloudflared (tunnel)** | 7/13 | Replaces port-forwarding for external access. Zero-config ingress with no open ports. Used alongside or instead of bare-metal ingress. |

### CNI (Container Networking)

| Tool | Repos | Notes |
|------|-------|-------|
| **Cilium** | 9/13 | Has largely replaced Flannel and Calico in modern homelab repos. eBPF-based, replaces kube-proxy, supports Gateway API, network policies, Hubble for observability. |
| **Calico** | 2/13 | Used in older or kubeadm-based setups (lisenet, khuedoan original). |
| **Flannel / default k3s** | 1/13 | Rare in sophisticated repos; mostly early-stage single-node k3s. |
| **Multus** | 2/13 | Used for multi-homed pods — IoT VLAN separation, Zigbee USB passthrough, etc. Typically added on top of Cilium. |

### Load Balancer (bare metal)

| Tool | Repos | Notes |
|------|-------|-------|
| **MetalLB** | 6/13 | Standard for bare-metal clusters without cloud LB. Layer2 mode common for home networks; BGP mode used by lisenet and nicolerenee. |
| **kube-vip** | 3/13 | Used as control plane VIP (HA API server) and optionally as service LB. Popular with kubeadm and k3s HA setups. |
| **Cilium LB-IPAM** | 3/13 | Cilium can serve as load balancer without MetalLB when using Cilium as CNI. Increasingly preferred to reduce component count. |

### Secret Management

| Tool | Repos | Notes |
|------|-------|-------|
| **External Secrets Operator (ESO)** | 8/13 | Pulls secrets from external stores into Kubernetes Secrets. Backends: 1Password Connect (most common), Bitwarden, AWS Secrets Manager, HashiCorp Vault. |
| **1Password Connect** | 5/13 | Most common ESO backend in high-quality repos. Requires 1Password subscription. |
| **SOPS + age** | 4/13 | Encrypts secrets at rest in git. Low infrastructure overhead. Preferred for simpler setups without a password manager. |
| **Sealed Secrets** | 2/13 | Controller + kubeseal CLI. Asymmetric encryption, safe to commit to git. Used in this repo and some ArgoCD setups. |
| **Bitwarden / Vaultwarden** | 2/13 | Self-hosted 1Password alternative as ESO backend. |

### Storage / CSI

See Section 4 for detailed breakdown.

### Monitoring & Alerting

| Tool | Repos | Notes |
|------|-------|-------|
| **kube-prometheus-stack** | 8/13 | Helm chart bundles Prometheus Operator, Prometheus, Alertmanager, node-exporter, kube-state-metrics, Grafana. Most common monitoring choice. |
| **Grafana** | 11/13 | Universal visualization layer. Deployed as part of kube-prometheus-stack or standalone with external datasources. |
| **Prometheus** | 10/13 | Time-series metrics. Almost always present alongside Grafana. |
| **Loki** | 5/13 | Log aggregation (Grafana ecosystem). Often deployed with Promtail or fluent-bit as log forwarders. |
| **VictoriaMetrics** | 3/13 | Drop-in Prometheus replacement. Lower resource usage. `victoria-metrics-k8s-stack` chart bundles operator + Grafana. Growing in homelab use. |
| **Victoria Logs** | 2/13 | VictoriaMetrics' log store, replacing Loki in some setups. |
| **Alertmanager** | 7/13 | Bundled with kube-prometheus-stack. Routes alerts to Slack, Discord, PagerDuty, Telegram. |
| **Gatus** | 5/13 | Kubernetes-native uptime/health endpoint monitoring. Config-as-code in YAML. Generates status pages. Lighter than Uptime Kuma for GitOps setups. |
| **Uptime Kuma** | 3/13 | UI-based uptime monitor. Very popular in Docker setups; used in some Kubernetes repos too. |
| **Headlamp** | 2/13 | Kubernetes dashboard (lightweight alternative to the official dashboard). Present in this repo. |
| **Hubble** | 3/13 | Cilium's built-in network observability. Provides flow visualization and network policy troubleshooting. |

### Backup

| Tool | Repos | Notes |
|------|-------|-------|
| **VolSync** | 7/13 | PVC-level backup/restore using Restic, Rclone, or rsync. Supports S3, NFS, B2. Pairs with snapshot controllers. Near-universal in Talos+Flux setups. |
| **Velero** | 2/13 | Full cluster backup (resources + PVCs). Used by lisenet with AWS S3. Higher overhead but backs up Kubernetes objects too. |
| **Longhorn built-in backup** | 2/13 | Longhorn has built-in S3/NFS backup for its volumes. Used by setups that already run Longhorn. |
| **CloudNativePG Barman** | 3/13 | Database-level WAL archiving to S3/NFS for PostgreSQL. Used in mitchross, nicolerenee, szinn. |

### Node Management / Cluster Ops

| Tool | Repos | Notes |
|------|-------|-------|
| **Reloader** | 6/13 | Watches ConfigMaps/Secrets and triggers rolling restarts automatically. Near-essential for config change propagation. |
| **Spegel** | 4/13 | Peer-to-peer in-cluster OCI image mirror. Avoids repeated upstream pulls on multi-node clusters. Used by onedr0p template. |
| **System Upgrade Controller** | 3/13 | Automates OS/k3s/Talos node upgrades declaratively. Pairs with Renovate for automated node version PRs. |
| **Node Feature Discovery (NFD)** | 3/13 | Labels nodes with hardware capabilities (GPU, iGPU, CPU flags). Required for GPU operators. |
| **Kyverno** | 3/13 | Policy engine for Kubernetes. Validates, mutates, generates resources. Used for image policy, pod security standards. |
| **KEDA** | 2/13 | Event-driven autoscaling. Scales pods based on external metrics (queue depth, cron, etc.). |
| **Descheduler** | 2/13 | Evicts pods from overloaded nodes and re-schedules them for better balance. |

---

## 3. Application Services — What People Typically Deploy

### Media Automation ("arr stack")

| App | Repos | What it does |
|-----|-------|-------------|
| **Jellyfin** | 9/13 | Open-source media server. Has largely displaced Plex in homelab Kubernetes repos due to no-cost and no-phone-home. |
| **Plex** | 4/13 | Commercial media server (free tier). Still popular, especially for existing Plex libraries. |
| **Emby** | 2/13 | Media server similar to Jellyfin/Plex. Less common. |
| **Sonarr** | 8/13 | TV show library management and automated download orchestration. |
| **Radarr** | 8/13 | Movie library management. |
| **Prowlarr** | 7/13 | Unified indexer manager for Sonarr/Radarr/Lidarr. Replaces Jackett. |
| **Bazarr** | 5/13 | Subtitle management for Sonarr/Radarr content. |
| **Lidarr** | 4/13 | Music library management. |
| **Readarr** | 3/13 | Book/ebook library management. |
| **qBittorrent** | 7/13 | Download client for torrents. Typically run behind a VPN (Gluetun). |
| **SABnzbd** | 4/13 | Usenet downloader. |
| **Autobrr** | 3/13 | IRC-based download automation, speeds up grabs vs RSS. |
| **Recyclarr** | 3/13 | Syncs Trash Guides quality profiles to Sonarr/Radarr. |
| **Jellyseerr** | 4/13 | Request management UI for Jellyfin (fork of Overseerr). |
| **Audiobookshelf** | 3/13 | Audiobook and podcast server with sync. |
| **Gluetun** | 5/13 | VPN container sidecar/gateway. Routes download traffic through WireGuard/OpenVPN providers. |

### Photos / Files

| App | Repos | What it does |
|-----|-------|-------------|
| **Immich** | 7/13 | Self-hosted Google Photos alternative. ML-based face detection, smart albums. One of the fastest-growing homelab apps. |
| **Nextcloud** | 4/13 | File sync, calendar, contacts, office suite. Heavy but comprehensive. |
| **Paperless-ngx** | 6/13 | Document scanning and OCR-based archive. Ingests PDFs/scans, adds tags and full-text search. |

### Home Automation / IoT

| App | Repos | What it does |
|-----|-------|-------------|
| **Home Assistant** | 8/13 | Home automation hub. Integrates with Z-Wave, Zigbee, MQTT, Matter. Usually runs on a VM or bare-metal alongside k8s rather than inside it (USB device access). |
| **ESPHome** | 4/13 | Firmware builder for ESP32/ESP8266 devices. Integrates with Home Assistant. |
| **Zigbee2MQTT** | 4/13 | Bridges Zigbee devices to MQTT. Runs alongside Home Assistant. |
| **Mosquitto** | 3/13 | MQTT broker. Often replaced by EMQX in newer setups. |
| **EMQX** | 2/13 | Enterprise-grade MQTT broker. Replacing Mosquitto in more recent repos. |
| **Frigate** | 4/13 | NVR (Network Video Recorder) with object detection via Coral TPU or GPU. Runs inside k8s with node selector for hardware. |
| **Music Assistant** | 2/13 | Music player with multiple provider integrations (Spotify, Tidal, local files). |

### Security / Authentication

| App | Repos | What it does |
|-----|-------|-------------|
| **Authentik** | 5/13 | Full-featured SSO/IdP. OIDC, SAML, LDAP. Acts as forward-auth proxy for Traefik/Nginx. Heavier than Authelia but more capable. |
| **Authelia** | 3/13 | Lightweight forward-auth proxy. 2FA, OIDC. Lower resource usage. Preferred for simpler setups. |
| **Kanidm** | 2/13 | Modern Rust-based LDAP/identity provider. Used by khuedoan and bjw-s. |
| **Vaultwarden** | 5/13 | Bitwarden-compatible password manager server. Written in Rust. Very low resource usage. |
| **LLDAP** | 2/13 | Lightweight LDAP server. Used as user directory backend for Authentik or Authelia. |
| **AdGuard Home** | 5/13 | DNS-level ad/tracker blocking. Often replaces Pi-hole. |
| **Pi-hole** | 3/13 | DNS ad blocker. Older deployments; being phased out in favor of AdGuard Home. |

### Productivity / Self-hosted SaaS

| App | Repos | What it does |
|-----|-------|-------------|
| **Gitea** | 4/13 | Lightweight self-hosted Git service. Used by khuedoan for Woodpecker CI integration. |
| **Woodpecker CI** | 2/13 | Lightweight CI/CD, integrates with Gitea. |
| **FreshRSS** | 3/13 | RSS feed aggregator. Web-based. |
| **Miniflux** | 2/13 | Minimalist RSS reader. Postgres-backed. |
| **Shlink** | 2/13 | URL shortener with analytics. |
| **Wiki.js** | 2/13 | Wiki platform with Markdown support and database backend. |
| **IT-Tools** | 3/13 | Collection of developer utilities (hash, encode, format). |
| **Ntfy** | 3/13 | Push notification service. Used for alerting from scripts/services. |
| **Actual Budget** | 2/13 | Personal finance / budgeting app. |
| **Changedetection** | 2/13 | Website change monitoring with notifications. |
| **Searxng** | 2/13 | Self-hosted metasearch engine. Privacy-focused alternative to Google. |
| **n8n** | 2/13 | Workflow automation (Zapier-like). |

### AI / LLM

| App | Repos | What it does |
|-----|-------|-------------|
| **Ollama** | 4/13 | Local LLM runner. Supports llama, mistral, gemma etc. Runs on CPU or GPU. |
| **Open WebUI** | 4/13 | ChatGPT-like frontend for Ollama and OpenAI API. |

### Databases / Middleware

| App | Repos | What it does |
|-----|-------|-------------|
| **CloudNativePG (CNPG)** | 6/13 | Kubernetes operator for PostgreSQL. Handles HA, failover, WAL archiving. Rapidly becoming the standard DB operator in homelab setups. 5k+ GitHub stars. |
| **Dragonfly Operator** | 2/13 | Redis-compatible in-memory cache. Drop-in replacement with better multi-threading. |
| **Redis** | 3/13 | Standard cache/queue backend for apps like Authentik, Nextcloud, Immich. |

### Dashboards

| App | Repos | What it does |
|-----|-------|-------------|
| **Homepage** | 5/13 | Service dashboard with widget support. Used by this repo. |
| **Dashy** | 3/13 | Customizable dashboard. Alternative to Homepage. |
| **Headlamp** | 2/13 | Kubernetes cluster dashboard (UI). Used in this repo. |

---

## 4. Persistence Layer — Detailed Breakdown

### Storage Solutions

| Solution | Repos using it | Profile |
|----------|----------------|---------|
| **Rook-Ceph** | 7/13 | Most capable. Provides block (RBD), filesystem (CephFS), and S3-compatible object (RGW). Required for `ReadWriteMany` volumes without NFS. Resource-hungry: 1–2 GB RAM per OSD node. Used by onedr0p, buroa, billimek, xunholy, toboshii, szinn, nicolerenee. Typical setup: 3+ nodes with dedicated SSDs as OSDs. |
| **Longhorn** | 3/13 | Simpler distributed block storage from Rancher. Built-in UI, S3/NFS backup, lower resource overhead (200–400 MB/node). Does not provide S3 object storage or CephFS. Used by mitchross, this repo's peer setups. Good for 1–3 node clusters. |
| **OpenEBS (local-hostpath / Mayastor)** | 3/13 | `local-path` (single-node) or `openebs-hostpath` for fast local storage; Mayastor for high-performance NVMe replication. bjw-s uses OpenEBS; nickclyde's homelab uses it via onedr0p template. |
| **NFS (TrueNAS / Synology)** | 8/13 | Used alongside block storage for media, bulk files, `ReadWriteMany` volumes. TrueNAS SCALE (ZFS) is the most common NAS backend. democratic-csi or nfs-subdir-external-provisioner provision PVCs from NFS shares. |
| **local-path-provisioner** | 5/13 | k3s default. Simple hostPath provisioner. Fine for single-node or ephemeral workloads; no redundancy. |

### Backup Tools

| Tool | Repos | Notes |
|------|-------|-------|
| **VolSync** | 7/13 | PVC-level incremental backup using Restic (default) to S3/NFS/B2. Restores individual volumes without full cluster restore. Supports ReplicationSource/Destination CRDs. Near-universal in Talos+Flux setups. Works with any CSI driver that supports VolumeSnapshots. |
| **CloudNativePG + Barman** | 4/13 | WAL archiving + base backups to S3/NFS for PostgreSQL. Separate from VolSync; gives point-in-time recovery for databases specifically. |
| **Velero** | 2/13 | Full cluster backup: both Kubernetes objects and PVC data. Supports S3 (AWS, MinIO, Backblaze B2). Higher overhead; useful when you need to restore an entire namespace or cluster. |
| **Longhorn built-in** | 2/13 | Longhorn UI / CRDs can push volume snapshots to S3/NFS targets. Good enough for many homelab needs without additional tooling. |
| **Kopia** | 2/13 | Backup engine used by mitchross. More configurable than Restic; can deduplicate across repositories. |

### Storage Architecture Patterns

**Pattern 1 — Rook-Ceph + VolSync (most common in Talos/Flux repos)**  
Rook-Ceph provides RBD block storage for databases and CephFS for shared volumes. VolSync backs up PVCs to B2 or S3 using Restic. CloudNativePG handles database backups separately via Barman.

**Pattern 2 — Longhorn + NFS**  
Longhorn handles block storage for apps requiring replication; NFS (TrueNAS) handles media and large files. Longhorn's built-in backup sends snapshots to S3/NFS. Lower cluster resource overhead than Rook-Ceph.

**Pattern 3 — OpenEBS local-path + NFS**  
OpenEBS hostpath for fast local PVCs on each node; NFS for shared/large storage. Cheapest resource profile. No inter-node replication for local volumes (no HA). Used in smaller or single-node setups.

**Pattern 4 — local-path + NFS (k3s default)**  
Simplest option: k3s local-path for app configs, TrueNAS/Synology NFS for everything else. No distributed storage overhead. Used in less-complex setups or when starting out.

---

## 5. Recommendations for This Homelab

Current stack: ArgoCD, Traefik, Longhorn, cert-manager, Sealed Secrets, External-DNS, Reloader, Renovate, Homepage.

### High-value additions (common across 8+ repos)

**1. Monitoring stack — kube-prometheus-stack**  
Absent from the current stack. Almost universal (8/13 repos). Deploy via `kube-prometheus-stack` Helm chart. Gives Prometheus, Grafana, Alertmanager, node-exporter, and kube-state-metrics in one release. Add community dashboards for Longhorn, Traefik, ArgoCD. Alert routing to Slack or ntfy for disk pressure, pod crash loops, certificate expiry.

**2. Gatus for service uptime**  
5/13 repos run Gatus. Config-as-code YAML monitoring for each service endpoint. Generates a public status page. Light on resources (~30 MB). Pairs well with ntfy for push alerts. Notably used by bjw-s, szinn, and hayneslab.

**3. VolSync for PVC backups**  
7/13 repos. Restic-based incremental PVC backups to S3 or NFS. Works with Longhorn (via VolumeSnapshot). Protects app data without snapshotting the entire Longhorn volume. Backblaze B2 is a popular cheap S3 target for homelab.

**4. CloudNativePG (CNPG)**  
6/13 repos. If any apps use PostgreSQL (Immich, Authentik, Gitea, Paperless-ngx all require Postgres), CNPG is the standard operator. Handles HA, automated failover, and WAL archiving. Replace standalone Postgres deployments with CNPG clusters.

**5. Authentik or Authelia for SSO**  
5/13 repos. Forward auth for Traefik: single login protects all internal services. Authentik is heavier but supports OIDC/SAML for apps like Immich, Gitea. Authelia is lighter and simpler if only forward-auth is needed. Both integrate with Traefik via ForwardAuth middleware.

### Medium-priority (common in 4–7 repos)

**6. Immich for photo management**  
7/13 repos. Fastest-growing self-hosted app. Requires PostgreSQL (CNPG), Redis (Dragonfly), and ~2 GB RAM. Provides Google Photos-equivalent features: face recognition, smart albums, mobile backup app.

**7. Jellyfin + arr stack**  
8/13 repos for Jellyfin; 7/13 for Sonarr/Radarr/Prowlarr. If running a media server, Jellyfin is the current community standard. The arr stack automates media acquisition. Pair with qBittorrent behind Gluetun VPN.

**8. Home Assistant**  
8/13 repos. If home IoT devices are in scope: deploy Home Assistant on a VM or bare metal node (USB device access is easier outside k8s). ESPHome and Zigbee2MQTT are common companions.

**9. Migrate from Sealed Secrets to External Secrets Operator + 1Password or Bitwarden**  
8/13 repos use ESO. ESO gives a better UX (secrets auto-sync, rotation support) and decouples secret rotation from GitOps commits. 1Password Connect is the premium option; self-hosted Vaultwarden works as a budget alternative if already deployed.

**10. Spegel for image caching**  
4/13 repos. Reduces upstream Docker Hub/registry pull load on multi-node clusters. Zero config after install. Included in the `onedr0p/cluster-template` by default.

### Lower priority / niche

**11. Cilium as CNI (if rebuilding)**  
9/13 repos. If the k8s cluster is ever rebuilt, Cilium replaces Flannel/Calico + kube-proxy. Enables eBPF, network policies, Hubble observability, and optionally replaces MetalLB and the ingress controller. Not worth a disruptive migration on a running cluster.

**12. Talos Linux (if rebuilding)**  
10/13 repos. Immutable, minimal Kubernetes OS. No SSH, no package manager, API-only management. Strongest security posture. Significant operational shift; best adopted when provisioning new hardware.

**13. Frigate NVR**  
4/13 repos. If IP cameras are in the picture. Requires hardware for object detection (Coral USB TPU or GPU). Integrates with Home Assistant.

**14. Ollama + Open WebUI**  
4/13 repos. Local LLM inference. Practical only with a discrete GPU or Apple Silicon. CPU-only inference is slow for most models beyond 7B parameters.

**15. Kyverno**  
3/13 repos. Policy enforcement: require resource limits, block privileged containers, enforce image registries. Useful once the cluster matures. Not critical early on.

---

## 6. Extended Source Repos (Round 2)

Additional repos found outside the initial 13. Stars accurate as of May 2026.

### High-star community repos

| Repo | Stars | OS | GitOps | CNI | Storage | Notable |
|------|-------|----|--------|-----|---------|---------|
| [techno-tim/k3s-ansible](https://github.com/techno-tim/k3s-ansible) | 3.0k | Debian/Ubuntu/Rocky | n/a (provisioning tool) | Calico or Cilium | — | Ansible playbook for HA k3s with kube-vip + MetalLB. Single-command cluster bootstrap. Molecule test suite. Galaxy collection. |
| [onedr0p/cluster-template](https://github.com/onedr0p/cluster-template) | 2.7k | Talos | Flux | Cilium | — | The community's canonical starting point. TOML config validated by CUE renders all manifests via makejinja. Defaults: Flux, Cilium, cert-manager, Envoy Gateway, External-DNS, Spegel, Reloader, Cloudflared. |
| [budimanjojo/talhelper](https://github.com/budimanjojo/talhelper) | 644 | Talos | n/a (tool) | — | — | CLI tool that generates Talos machine configs in a GitOps-friendly way. SOPS-native. Widely used across Talos repos alongside the cluster-template. |
| [ricsanfre/pi-cluster](https://github.com/ricsanfre/pi-cluster) | 539 | Ubuntu (hybrid ARM+x86) | Flux | Cilium | Longhorn | Hybrid Raspberry Pi + mini-PC cluster. Ansible + Terraform provisioning. Full observability: Prometheus, Grafana, Loki, Elasticsearch. Vault, Keycloak, Kafka via Strimzi, Istio service mesh. Dedicated Pi running OpenWRT as cluster firewall. Comprehensive docs at picluster.ricsanfre.com. |
| [bjw-s-labs/helm-charts](https://github.com/bjw-s-labs/helm-charts) | 1.0k | — | — | — | — | The `app-template` chart (requires Kubernetes ≥1.28). Wraps a common library to deploy any app without a dedicated chart. Near-universal in community Flux repos. Successor to the deprecated k8s-at-home/charts. |
| [carpenike/k8s-gitops](https://github.com/carpenike/k8s-gitops) | 312 | Talos | Flux v2 | — | — | git-crypt + SOPS dual secrets strategy. Pre-commit hooks. Home Operations Discord contributor. Archived Sep 2025; successor in progress. |
| [vehagn/homelab](https://github.com/vehagn/homelab) | 388 | Proxmox VMs → Talos | ArgoCD | Cilium | Proxmox CSI + TrueNAS | OpenTofu (open-source Terraform fork) for infra provisioning. Kustomized Helm with ArgoCD. Gateway API instead of Ingress. CloudNativePG. The blog at blog.stonegarden.dev covers Talos+Proxmox+OpenTofu and BGP/Cilium in depth. |
| [brettinternet/homeops](https://github.com/brettinternet/homeops) | 257 | Talos (bare-metal) | Flux | Cilium | Rook-Ceph + MergerFS | Hybrid: 5× Raspberry Pi 4B (USB SSD) + bare-metal nodes. Rook-Ceph distributed storage. Cilium L4 LB (no MetalLB). CloudNativePG, Authelia OIDC, K8s Gateway for local DNS. go-task for ops shortcuts. |
| [budimanjojo/home-cluster](https://github.com/budimanjojo/home-cluster) | 248 | Talos | Flux | Cilium | Rook-Ceph + NFS | talhelper-built. Cilium as CNI + LB (no MetalLB). OPNsense → Envoy Gateway traffic path. SOPS+age. Intel GPU plugin. Dynamic Grafana dashboard via ConfigMap sidecar pattern. |
| [gruberdev/homelab](https://github.com/gruberdev/homelab) | 247 | Talos | ArgoCD | — | democratic-csi (ZFS) | argocd-image-updater for automatic image promotion back to git. Reflector for cross-namespace Secret/ConfigMap sync. Descheduler for pod balance. kube-fledged for pre-caching images. Wavy for VNC-in-browser on containers via annotations. Vault for secrets. |
| [danmanners/homelab-kube-cluster](https://github.com/danmanners/homelab-kube-cluster) | 234 | Ubuntu + Talos | ArgoCD | Cilium (eBPF) | Rook-Ceph + NFS | Argo Events + Argo Workflows alongside ArgoCD. Tekton for cloud-native CI. Dex IDP. Maddy mail server. Harbor private registry. WikiJS. Archived Sep 2025. |
| [wrmilling/k3s-gitops](https://github.com/wrmilling/k3s-gitops) | 227 | NixOS nodes | Flux v2 | — | Rook-Ceph | NixOS for reproducible node config (rare in homelab k8s repos). Mini-PC nodes (Minisforum UN100C + BMax B4) + TrueNAS master VM. |
| [angelnu/k8s-gitops](https://github.com/angelnu/k8s-gitops) | 181 | CentOS 10 Stream (Proxmox VMs) | Flux v2 | — | — | Migration in progress from k3s to OKD (open-source OpenShift). Terraform + cloud-init for VM templates. Separate service VM (management layer) for installer orchestration. |
| [auricom/home-ops](https://github.com/auricom/home-ops) | 206 | Talos | Flux v2 | — | — | Python (22%) + Just (16%) for operations tooling, alongside Flux manifests. RenovateBot. |

### Smaller but architecturally interesting repos

| Repo | Stars | OS | GitOps | Notable |
|------|-------|----|--------|---------|
| [clearlybaffled/homelab](https://github.com/clearlybaffled/homelab) | 70 | Debian | ArgoCD | kubeadm bootstrap, CRI-O runtime, Flannel CNI, MetalLB, FreeIPA for identity, offline root CA with scripted OpenSSL PKI, NetBox for inventory, Keycloak. Entire home network (OPNsense, workstations, Cisco switch) declared in one repo. |
| [prankstr/homelab](https://github.com/prankstr/homelab) | 45 | Talos VMs on Proxmox | Flux | Piraeus/LINSTOR (ZFS-backed) storage. Single physical server virtualises everything including router (OPNsense VM). Authentik, Mealie, OpenCloud, Vikunja, VictoriaMetrics. |
| [tylertitsworth/ai-cluster](https://github.com/tylertitsworth/ai-cluster) | 58 | Ubuntu 22.04 | ArgoCD | Turing Pi 2 board: 2× RK1 (NPU) + 2× Jetson Orin Nano (GPU). Custom RK1 NPU device plugin. Distributed PyTorch Lightning training via Gloo backend. Flyte for ML orchestration. Ollama + Open WebUI + Chroma. Tailscale for remote access. Custom Jetson Prometheus exporter. |
| [fenio/homelab](https://github.com/fenio/homelab) | 31 | Talos (via Sidero Omni) | Flux v2 | Cilium with kube-proxy replacement + WireGuard encryption + BGP control plane. TrueNAS-backed tns-csi (NFS/iSCSI/NVMe-oF). VictoriaMetrics + Grafana + Coroot APM + Hubble. Kyoo transcoding server. Ollama with ROCm GPU. CloudNative-PG. Demonstrates Sidero Omni for GUI-based Talos cluster management. |

---

## 7. New Findings — Tools and Patterns Not Well Represented in Round 1

### 7.1 Tooling Infrastructure

**onedr0p/cluster-template** is the effective standard starting point for new Flux+Talos homelabs. Its defaults have shifted community practice: Envoy Gateway replaced ingress-nginx as the default ingress, Spegel is included out of the box, and CUE schema validation of the TOML config file catches errors before `makejinja` renders YAML. Over 2,700 stars and hundreds of forks.

**talhelper** (644 stars) fills the gap between Talos's `talosctl genconfig` and GitOps. It reads a `talconfig.yaml` with SOPS-encrypted secrets and renders per-node machine configs. Widely used with the cluster-template. The `talhelper gensecret` command initialises the Talos PKI and secrets file in one step.

**kubesearch.dev** — community search engine indexing HelmRelease configurations from public homelab repos. Useful for finding real-world `values.yaml` patterns for any chart across hundreds of repos. Complements the Helm chart docs.

**app-template (bjw-s-labs/helm-charts)** — the replacement for the deprecated `k8s-at-home/charts`. A single generic Helm chart that renders any app's Deployment/Service/Ingress/PVC from a structured values file. Requires Kubernetes ≥1.28. 1,000+ stars. Used in nearly every active Flux community repo.

### 7.2 Networking Shifts

**Cilium BGP control plane replacing MetalLB** is the dominant new pattern in 2025–2026. Instead of MetalLB L2/BGP + Cilium CNI, most new repos run Cilium alone with `BGPPeeringPolicy` CRDs advertising LoadBalancer IPs to a router (UniFi, OPNsense, VyOS). Eliminates a component and gives native eBPF path for LB traffic. blog.stonegarden.dev documents the migration from MetalLB to Cilium L2 and then to BGP peering with UniFi. Key config: `externalTrafficPolicy: Cluster` vs `Local` tradeoffs still apply.

**Ingress-NGINX end-of-life (March 2026)** — the official ingress-nginx maintainers announced EOL. The community is migrating to Gateway API implementations. `onedr0p/cluster-template` already defaults to **Envoy Gateway**. Cilium's Gateway API implementation is the other common choice (no extra component if Cilium is already the CNI). The CNCF `ingress2gateway` tool (v1.0, March 2026) converts existing Ingress objects to Gateway API resources and handles 30+ common annotations.

**Sidero Omni** — Siderolabs' commercial-but-free-tier (or self-hostable) control plane for Talos clusters. GUI for cluster lifecycle, node allocation, upgrades, and kubeconfig distribution. `fenio/homelab` demonstrates Omni managing the same Talos cluster that Flux manages the workloads on. Self-host option via the open-source `siderolabs/omni` repo. Useful when managing more than one cluster or when non-technical co-owners need to restart nodes.

### 7.3 Storage — New and Diverging Patterns

**Piraeus / LINSTOR** — DRBD-based block storage managed by the Piraeus Operator (CNCF sandbox). Backed by ZFS or LVM. Lower RAM overhead than Rook-Ceph; no object storage or CephFS, but synchronous replication is faster for database workloads. `prankstr/homelab` uses it. LINBIT maintains an official homelab blog post. Alternative to Longhorn for users with ZFS-capable nodes.

**Garage (self-hosted S3)** — MinIO's AGPLv3 relicensing in 2025 and subsequent stripping of the community GUI has driven homelabbers to **Garage** (Rust, ~50 MB binary, MIT licence). Garage provides S3-compatible object storage for VolSync targets, Loki/Mimir/Tempo chunks, and Longhorn backups. `meroxdotdev/infrastructure` uses Garage on a VPS as the off-site backup target. Migration guides from MinIO to Garage proliferated across homelab blogs in late 2025.

**democratic-csi with TrueNAS** — remains popular for NFS/iSCSI provisioning from TrueNAS SCALE. `gruberdev/homelab` and `rafaribe/home-ops` use it with ZFS-backed datasets. Provides both `ReadWriteOnce` iSCSI block and `ReadWriteMany` NFS volumes from the same appliance.

### 7.4 Observability Trends

**Grafana Alloy** replaced Grafana Agent (deprecated early 2024) as Grafana Labs' OpenTelemetry-compatible collector. The `grafana/k8s-monitoring` Helm chart deploys multiple Alloy components: `alloy-metrics` (cluster metrics to Prometheus/Mimir), `alloy-logs` (pod/node logs to Loki), `alloy-singleton` (Kubernetes events). Replaces Promtail in new deployments. Programmable River config language.

**VictoriaMetrics** continues gaining ground over kube-prometheus-stack in resource-constrained homelab nodes. The `victoria-metrics-k8s-stack` Helm chart is a drop-in replacement bundling the VictoriaMetrics operator, VMAgent, VMAlert, and Grafana. `nicolerenee/infra` and `fenio/homelab` use it. VictoriaLogs is the companion log store replacing Loki for lower RAM usage. `prankstr/homelab` runs VictoriaMetrics as its full observability stack.

**Coroot** — application-level APM for Kubernetes based on eBPF. No code instrumentation needed. Surfaces RED metrics (Rate, Errors, Duration) per service automatically. `fenio/homelab` runs Coroot alongside VictoriaMetrics and Hubble.

### 7.5 Secret Management — Newer Patterns

**External Secrets + Bitwarden/Vaultwarden** — an alternative to the 1Password ESO backend for those without a 1Password subscription. A Bitwarden CLI pod acts as a webhook provider for ESO's `ClusterSecretStore`. Self-hosted Vaultwarden can serve as the backend. Morey.tech documents the integration.

**Akeyless** — cloud-hosted secrets manager with a free tier that `rafaribe/home-ops` uses as an alternative to HashiCorp Vault. ESO has a native Akeyless provider.

### 7.6 AI/Edge Patterns (Emerging)

**Heterogeneous compute on Turing Pi 2** — `tylertitsworth/ai-cluster` runs Turing RK1 (ARM SoC with NPU) + Jetson Orin Nano (GPU) nodes on a single Turing Pi 2 board. Custom device plugins expose NPU resources as Kubernetes-schedulable resources. PyTorch Lightning distributed training via Gloo backend (avoids NCCL P2P requirements). Flyte for ML workflow orchestration.

**Ollama + ROCm GPU** — `fenio/homelab` runs Ollama with AMD ROCm GPU support on Talos. The AMD GPU operator is available but less mature than NVIDIA's; requires `amdgpu` kernel module loaded via Talos extensions.

---

## 8. Community Resources and Templates

### Primary Communities

**Home Operations Discord** (formerly k8s-at-home) — the central community for homelab Kubernetes. Thousands of members share configs, debug issues, and maintain shared tooling (the cluster-template, helm-charts, containers image repo). Invite link via [k8s-at-home.com](https://k8s-at-home.com/).

**h3mmy/awesome-home-kubernetes** — curated GitHub list of homelab Kubernetes repos, Helm chart collections, and tooling. More up-to-date than most awesome lists for this niche.

### Template Starting Points

| Template | Description |
|----------|-------------|
| [onedr0p/cluster-template](https://github.com/onedr0p/cluster-template) | The canonical Talos+Flux template. Start here for any new Talos cluster. |
| [techno-tim/k3s-ansible](https://github.com/techno-tim/k3s-ansible) | Best starting point for k3s HA on existing Ubuntu/Debian/Rocky nodes. Supports Calico or Cilium BGP. |
| [bee42/homelab](https://github.com/bee42/homelab) | Opinionated template supporting k0s, k3s, or Talos with Flux. Good for comparing distributions. |

### Notable Blogs

| Blog | Notable Content |
|------|----------------|
| [blog.stonegarden.dev](https://blog.stonegarden.dev/) | Talos+Proxmox+OpenTofu series; MetalLB→Cilium migration; BGP with UniFi+Cilium; Gateway API with Cilium and cert-manager; Cilium Direct Server Return. Corresponds to `vehagn/homelab` repo. |
| [picluster.ricsanfre.com](https://picluster.ricsanfre.com/) | Full documentation site for `ricsanfre/pi-cluster`. ARM/x86 hybrid cluster, Ansible automation, Cilium, Longhorn, Vault, Keycloak, Kafka, Istio. Most comprehensive free homelab k8s guide available. |
| [technotim.com](https://technotim.com/) | YouTube+blog. k3s-ansible, Renovate setup, "What I'm Running in My Homelab 2026" app survey. Accessible for beginners. |
| [merox.dev/blog](https://merox.dev/blog/homelab-tour/) | "Homelab 2026" tour: Proxmox cluster, Talos, Flux, full rebuild in 8–9 minutes. |
| [blog.azaurus.dev](https://blog.azaurus.dev/how-i-host-my-homelab/) | GitOps-first homelab walkthrough using VictoriaMetrics for observability. |

### Useful Search and Discovery Tools

- **[kubesearch.dev](https://kubesearch.dev/)** — search HelmRelease configs from hundreds of public homelab repos. Filter by chart, version, and repo stars. Best way to find real-world `values.yaml` for any chart.
- **[home-operations/containers](https://github.com/home-operations/containers)** (396 stars) — community-maintained container images with automated Renovate-compatible tagging. Used when upstream images lack semantic versioning.

### Key Tooling Repos (not homelab configs, but used universally)

| Tool | Stars | Purpose |
|------|-------|---------|
| [spegel-org/spegel](https://github.com/spegel-org/spegel) | — | Stateless peer-to-peer in-cluster OCI mirror. GA in k3s since Dec 2024. |
| [backube/volsync](https://github.com/backube/volsync) | — | PVC backup/restore operator. Restic, Rclone, rsync backends. |
| [cloudnative-pg/cloudnative-pg](https://github.com/cloudnative-pg/cloudnative-pg) | 5k+ | PostgreSQL operator. HA, failover, Barman WAL archiving. |
| [piraeusdatastore/piraeus-operator](https://github.com/piraeusdatastore/piraeus-operator) | — | LINSTOR/DRBD block storage for k8s. CNCF sandbox. ZFS-backed. |
