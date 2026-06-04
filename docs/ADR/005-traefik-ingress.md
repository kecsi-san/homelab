---
title: "005 — Traefik as Ingress Controller"
type: adr
status: accepted
scope: [k8s, k3s]
created: 2026-04-01
updated: 2026-05-17
tags: [traefik, ingress, networking, tls, forwardauth]
---

# 005 — Traefik as Ingress Controller

## Status

Accepted

## Context

Both clusters need an ingress controller to route external HTTP/HTTPS traffic to
in-cluster services, terminate TLS, and implement access control middleware. The
controller must support:

- **IngressRoute CRDs**: more expressive than standard `Ingress` objects
- **Middleware**: specifically `forwardAuth` for Authentik SSO integration
- **Let's Encrypt integration**: automated TLS via DNS01 challenges (Cloudflare)
- **Dashboard**: visibility into routing rules without reading raw YAML
- **Cloudflare Tunnel compatibility**: acting as the backend for `cloudflared`
- **Lightweight**: the homelab nodes are not large servers; the ingress controller
  must not consume significant resources

## Decision

Use **Traefik** (v3.x) as the ingress controller on both clusters:

- Deployed via Helm (`traefik/traefik` chart) managed by ArgoCD
- LoadBalancer service with kube-vip IP: `192.168.1.101` (k8s), k3s equivalent
- TLS terminated at Traefik for LAN path (cert-manager LE certificates per service)
- Traefik acts as backend for `cloudflared` (Cloudflare path, `noTLSVerify: true`)
- `forwardAuth` middleware (`middleware-authentik-forwardauth.yaml`) wires Authentik
  SSO to Longhorn UI, Traefik dashboard, and other protected services

Traefik runs in **insecure mode** (for the dashboard IngressRoute); TLS is handled
at the IngressRoute level, not at the Traefik entrypoint.

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| **nginx-ingress (ingress-nginx)** | Standard `Ingress` objects are less expressive; middleware for forwardAuth requires annotations rather than first-class CRDs; heavier config for Authentik integration |
| **HAProxy Ingress** | Good performance but no native middleware system; forwardAuth would require external configuration; smaller k8s community |
| **Envoy / Istio** | Service mesh features (mTLS between pods, traffic splitting) are beyond the homelab's needs; Istio's operational complexity and resource usage are disproportionate |
| **Caddy** | Excellent automatic HTTPS but not k8s-native; lacks CRD-based routing; best as a standalone reverse proxy, not a k8s ingress controller |
| **Kong** | Feature-rich API gateway but heavy and complex for a homelab; free tier does not include all enterprise features |

## Consequences

**Positive:**
- `IngressRoute` CRDs provide clean, readable routing configuration with middleware
  composition (e.g. a route can reference `authentik-forwardauth` middleware in one line)
- The `forwardAuth` middleware enables Authentik SSO for any service without modifying
  the service itself — simply add the middleware reference to its IngressRoute
- Traefik dashboard at `traefik.kecskemethy.org` (protected by forwardAuth) shows
  all active routes, middleware, and entrypoints at a glance
- cert-manager integration is straightforward: Certificate CR → TLS secret → IngressRoute
  `tls.secretName`
- Cloudflare Tunnel uses Traefik as a single backend (`https://traefik.traefik.svc.cluster.local`)
  with `noTLSVerify: true`; all routing intelligence stays in Traefik

**Negative / Trade-offs:**
- Traefik's IngressRoute CRDs are non-standard; manifests are not portable to clusters
  using nginx-ingress without rewriting
- The dual TLS path (LAN cert-manager certs + Cloudflare Universal SSL) means each
  service has two TLS termination points; browser cert warnings can appear if the LAN
  path is used with a Cloudflare-only CNAME
- Traefik v3 introduced breaking changes from v2; `middlewares` references in IngressRoutes
  must include the namespace (`traefik` prefix on cross-namespace references)
- Traefik insecure mode means the dashboard entrypoint is unencrypted; rely on forwardAuth
  and network trust rather than TLS for the dashboard path
