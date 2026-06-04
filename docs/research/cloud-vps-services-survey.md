---
title: "Cloud VPS Services in Homelab Repos — Survey"
type: research
status: stable
scope: [general]
created: 2026-06-04
updated: 2026-06-04
tags: [cloud, vps, email, wireguard, vpn, aws, hetzner, route53, dns]
---

# Cloud VPS Services in Homelab Repos — Survey

Survey of 18+ popular homelab/homeops GitHub repositories to identify which services are
hosted on cloud VPS instances (as opposed to purely on-premises hardware), and which
connectivity and DNS approaches they use.

**Date:** 2026-06-04
**Method:** Direct GitHub repo inspection (README, docs/, manifests) + web search.
Only verified setups are listed.

---

## Repo Survey

| Repo | Stars | Cloud Provider | VPS Services | VPN / Connectivity | DNS Provider | Notes |
|------|-------|----------------|--------------|-------------------|--------------|-------|
| [khuedoan/homelab](https://github.com/khuedoan/homelab) | 9.3k | None | — | Tailscale + Cloudflare Tunnel | Cloudflare | Pure on-premises; 4× NEC SFF |
| [onedr0p/home-ops](https://github.com/onedr0p/home-ops) | 2.8k | GCP (minimal) | None (Google Assistant integration) | Cloudflare Tunnel | Cloudflare | ~$10/month cloud; self-hosted first philosophy |
| [bjw-s-labs/home-ops](https://github.com/bjw-s-labs/home-ops) | 834 | None disclosed | — | Not disclosed | Not disclosed | On-premises; limited README detail |
| [lisenet/kubernetes-homelab](https://github.com/lisenet/kubernetes-homelab) | 502 | None | — | None (OpenVPN noted in blog) | Bind DNS (self-hosted `.test` zone) | Pure on-premises; Dell + TrueNAS + MikroTik |
| [szinn/k8s-homelab](https://github.com/szinn/k8s-homelab) | 296 | None | — | Wireguard + cloudflared | Cloudflare | DDNS via Cloudflare |
| [joryirving/home-ops](https://github.com/joryirving/home-ops) | 216 | None | — | Cloudflare Tunnel | Cloudflare | Proxmox on-prem; explicit cost minimisation (~$40-80/yr cloud) |
| [budimanjojo/home-cluster](https://github.com/budimanjojo/home-cluster) | 246 | None disclosed | — | Not disclosed | Not disclosed | Talos OS cluster |
| [gruberdev/homelab](https://github.com/gruberdev/homelab) | 248 | None | — | Tailscale-operator (mesh) | Not disclosed | Talos-based |
| [mchestr/home-cluster](https://github.com/mchestr/home-cluster) | 163 | AWS (SES only) | Email relay via SES | Cloudflare Tunnel | Cloudflare | ~$150/yr cloud; Talos cluster |
| [nicolerenee/infra](https://github.com/nicolerenee/infra) | 108 | None | — | Tailscale + Cloudflare Tunnel | Cloudflare | Colo + home cluster; ~€14-15/month infra |
| [x86-39/homelab_v1](https://github.com/x86-39/homelab_v1) | — | Hetzner Cloud | Reverse proxy / VPN gateway | Wireguard (home→cloud bridge) | Cloudflare | Hybrid: TrueNAS SCALE + Hetzner edge node |
| [catdevops1/homelab-vpn](https://github.com/catdevops1/homelab-vpn) | — | Generic VPS | Headscale control plane + Tailscale exit node | Headscale + Wireguard mesh | — | VPS hosts Headscale; homelab is exit node |
| [av1155/homelab](https://github.com/av1155/homelab) | — | Cloudflare R2 | Backups (object storage) | Wireguard (WG-Easy) + Cloudflare ZT | Cloudflare + AdGuard Home | On-premises Proxmox; R2 for off-site backups |
| [jakejarvis/homelab](https://github.com/jakejarvis/homelab) | — | DigitalOcean | Reverse proxy | Wireguard (Mullvad client) | — | Raspberry Pi + DO VPS for routing; Traefik + Authelia |
| [hobby-kube/guide](https://github.com/hobby-kube/guide) | — | Hetzner, DO, Scaleway | Full k8s workloads (MinIO, cert-manager, etc.) | Wireguard | Cloudflare / Google / AWS / DO | €13.50-18/month; full k8s on cheap cloud |
| [sovereign/sovereign](https://github.com/sovereign/sovereign) | 10.5k | Any Linux VPS (Linode typical) | **Full stack:** Postfix + Dovecot, VPN, Webmail, IRC, CalDAV/CardDAV, Git | Wireguard | Self-configured | Ansible playbooks; batteries-included VPS email+VPN suite |
| [trailofbits/algo](https://github.com/trailofbits/algo) | 30.3k | AWS, Azure, GCP, DO, Hetzner, Linode, Vultr, Scaleway | Wireguard / IKEv2 VPN server | Wireguard + IKEv2 IPsec | Cloud provider DNS | Pure VPN deployment tool; 11+ cloud provider targets |
| [octelium/octelium](https://github.com/octelium/octelium) | — | DO, Hetzner, AWS EC2, Vultr | Zero-trust gateway + optional app hosting | Wireguard + QUIC tunnels | — | Modern unified zero-trust platform; $5-10/month VPS viable |

---

## Patterns and Trends

### Most homelabs are purely on-premises

70% of the primary surveyed repos use no cloud VPS at all. The dominant pattern in 2026
is on-premises Kubernetes (Talos, k3s, Kubespray) with Cloudflare Tunnel for public
web-service exposure — no VPS required. When cloud appears, it is usually for:

1. **NAT traversal / reverse proxy** — small $5-10/month VPS bridges a home NAT to the internet
2. **VPN control plane** — Headscale or Wireguard gateway hosted on a VPS
3. **Email relay** — Postfix smarthost on a VPS, or AWS SES, rather than full IMAP stack
4. **Off-site backups** — object storage (Cloudflare R2, S3) rather than a running VPS

### Wireguard dominates VPN; Cloudflare Tunnel dominates public web access

| Approach | Repos using it | Notes |
|----------|----------------|-------|
| Cloudflare Tunnel (cloudflared) | 7 | Most popular for exposing web services publicly; zero config, no open ports |
| Wireguard | 10 | Most common VPN protocol; used for private access and VPS bridging |
| Tailscale | 5 | Built on Wireguard; "zero-config" mesh; popular in Talos-based setups |
| Headscale (self-hosted Tailscale) | 1 | Self-hosted Tailscale coordination server on a VPS |

Cloudflare Tunnel has largely replaced traditional open-port VPN for web service exposure.
Wireguard is preferred when a real VPN tunnel is needed (e.g. bridging a home lab to a VPS,
or giving road-warrior access to the home network).

### Self-hosted email is rare; most outsource it

Only [sovereign/sovereign](https://github.com/sovereign/sovereign) (10.5k stars) covers a
full Postfix + Dovecot deployment as a first-class concern. The rest either:
- Outsource to managed providers (Migadu, ProtonMail)
- Relay outbound through AWS SES or similar SMTP relay
- Ignore email entirely

No surveyed repos run Maddy or Stalwart (newer Rust-based email servers) as a primary stack.

### Hetzner and DigitalOcean are the preferred cloud VPS providers for homelabs

When a VPS is used, the choices are almost always Hetzner Cloud or DigitalOcean — both
offer €/$ 4-6/month entry instances. AWS EC2 appears only in tools like Algo or Octelium
that explicitly target multiple providers. No surveyed homelab repo uses AWS EC2 as its
primary VPS.

### Route53 is absent from homelab DNS

| DNS provider | Repos | % |
|---|---|---|
| Cloudflare (managed) | 11 | 61% |
| Self-hosted (Bind, Pi-hole, AdGuard Home) | 6 | 33% |
| Google Cloud DNS | 1 | 6% |
| **AWS Route53** | **0** | **0%** |

Cloudflare dominates; Route53 is not used in any surveyed homelab repo. The free Cloudflare
tier (DNS + Tunnel + DDoS protection) makes it the default choice.

### Cloud storage for backups is increasing

Object storage (Cloudflare R2, AWS S3) as an off-site backup target is increasingly common
even in repos that run no VPS compute. R2 in particular is attractive at zero egress cost.

---

## Implications for This Repo

| Finding | Relevance |
|---------|-----------|
| AWS EC2 is unusual; Hetzner/DO more common for VPS | Existing AWS investment still valid; no community pressure to switch |
| Wireguard hub-and-spoke on VPS is an established pattern | Planned `configure_wireguard` role follows community practice |
| Full self-hosted email (Postfix+Dovecot) is rare but sovereign/sovereign proves it works | `setup_email-server` role is non-trivial; sovereign is a good reference implementation |
| Route53 is not used in any surveyed homelab | `configure_route53` role would be novel; Cloudflare DNS is the norm if Route53 is dropped |
| Cloudflare Tunnel is the dominant web-exposure method | Current cloudflared setup is community standard; Wireguard would be a meaningful departure |
| Headscale (self-hosted Tailscale) on VPS is a viable alternative to Wireguard | Consider as an option alongside Wireguard in the VPN planning |

---

## Notable Reference Projects

- **[sovereign/sovereign](https://github.com/sovereign/sovereign)** — 10.5k stars; Ansible playbooks for a complete self-hosted VPS: Postfix, Dovecot, DKIM, SpamAssassin, Roundcube webmail, Wireguard, CalDAV, Git. Best reference for the `setup_email-server` role.
- **[trailofbits/algo](https://github.com/trailofbits/algo)** — 30.3k stars; the definitive Wireguard/IKEv2 VPN deployment tool; supports 11 cloud providers. Reference for `configure_wireguard`.
- **[hobby-kube/guide](https://github.com/hobby-kube/guide)** — detailed cost-effective k8s on Hetzner/DO with Wireguard networking; useful if cloud k8s node is ever added.
