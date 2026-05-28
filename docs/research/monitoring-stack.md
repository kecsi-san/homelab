# Monitoring Stack Research

**Date:** 2026-05-28  
**Context:** 4-node bare-metal Kubespray cluster (3 CP + 1 worker), Longhorn storage, Traefik ingress, ArgoCD GitOps, Authentik SSO. Single-node k3s on WSL2. Existing: Gatus (HTTP uptime), ntfy (push notifications), Garage (S3-compatible object storage).

## Decision

**Chosen: `kube-prometheus-stack`** — Prometheus + Grafana + AlertManager + node-exporter + kube-state-metrics via the `prometheus-community/kube-prometheus-stack` Helm chart.

See TODO.md for implementation tasks.

---

## Options Evaluated

### kube-prometheus-stack

Single Helm chart bundling the full observability stack:
- Prometheus Operator + Prometheus
- Grafana (OSS)
- AlertManager
- Node Exporter
- kube-state-metrics
- Pre-configured dashboards and alerting rules

**Resource footprint:** Prometheus ~500m CPU / 2Gi RAM baseline; Grafana ~300m CPU / 512Mi RAM. Storage: ~50Gi for 15-day retention. Acceptable on this cluster (each node has ~79–83 GB free on /var).

**Kubespray / bare-metal:** Fully compatible, no known issues.

**Why chosen:** Community standard, battle-tested, lowest operational complexity, massive ecosystem of pre-built dashboards (node overview, Longhorn, Traefik, ArgoCD all available on Grafana Labs).

### VictoriaMetrics (`victoria-metrics-k8s-stack`)

Drop-in Prometheus-compatible stack with VictoriaMetrics as the time-series backend instead of Prometheus. Also bundles Grafana, kube-state-metrics, and pre-built dashboards.

**Advantages over kube-prometheus-stack:**
- 10× better storage compression
- Lower memory footprint under high cardinality
- Simpler multi-node / long-retention story

**Why not chosen (for now):** Adds operational complexity without clear benefit at homelab scale. The 4-node cluster has headroom. **Revisit if Prometheus memory pressure becomes an issue**, or if long-term retention (beyond 15 days) is needed.

**Upgrade path:** VictoriaMetrics supports Prometheus remote-write — can switch backends without losing dashboards or alert rules.

### Other Options Considered

| Option | Verdict |
|--------|---------|
| **Thanos** | Long-term object storage sidecar for Prometheus. Relevant if retention >15 days is needed — Garage (already deployed, S3-compatible) is a ready target. Add later, not needed initially. |
| **Grafana Mimir** | Enterprise-grade, horizontally scalable, multi-tenant. Overkill for a homelab. |
| **InfluxDB** | Less Kubernetes-native, weaker Prometheus ecosystem integration. Skip. |
| **Grafana Alloy** | Successor to Grafana Agent (EOL Nov 2025); unified OTel collector for metrics + logs + traces. Overkill for metrics-only homelab. Skip unless adding distributed tracing later. |

---

## Alerting

**Chosen: AlertManager** (bundled in kube-prometheus-stack) with ntfy webhook.

- Minimal resource overhead
- Single YAML config, GitOps-friendly
- ntfy webhook integration is well-documented
- Already have ntfy deployed and working for VolSync backup alerts

**Grafana Alerting** (the Grafana-native alternative): supports multi-datasource alerting (Loki, CloudWatch, PostgreSQL, etc.) but higher operational complexity and harder HA. Not needed for metrics-only homelab.

---

## Long-term Retention

Garage is already deployed as an S3-compatible object store with a `volsync-backups` bucket. When 15-day Prometheus retention becomes limiting:

1. **Option A — Thanos sidecar:** Add Thanos sidecar to Prometheus; ship blocks to Garage. Keeps kube-prometheus-stack as-is.
2. **Option B — Switch to VictoriaMetrics:** Remote-write from Prometheus to VictoriaMetrics, or replace kube-prometheus-stack with victoria-metrics-k8s-stack entirely.

No new storage infrastructure needed for either path.

---

## Kromgo

[kashalls/kromgo](https://github.com/kashalls/kromgo) — lightweight Go app that exposes named Prometheus queries as simple HTTP endpoints. Used to display live cluster metrics as tiles in the Homepage dashboard (replaces the broken Kubernetes metrics widget removed earlier).

**Typical metrics to expose:** cluster CPU%, cluster RAM%, pod count, node count, Longhorn volume health.

**Alternative:** gethomepage.dev's native Grafana widget — simpler if you just want a panel embed, but Kromgo gives more control over individual metric values.

**Dependency:** Requires the monitoring stack (Prometheus endpoint) to be deployed first.

---

## Sources

- [VictoriaMetrics vs Prometheus comparison](https://last9.io/blog/prometheus-vs-victoriametrics/)
- [kube-prometheus-stack on ArtifactHub](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack)
- [VictoriaMetrics K8s Stack docs](https://docs.victoriametrics.com/helm/victoria-metrics-k8s-stack/)
- [AlertManager vs Grafana Alerting (2026)](https://alexandre-vazquez.com/alertmanager-vs-grafana-alerting/)
- [Grafana Agent → Alloy migration FAQ](https://grafana.com/blog/grafana-agent-to-grafana-alloy-opentelemetry-collector-faq/)
- [Kromgo GitHub](https://github.com/kashalls/kromgo)
- [TechnoTim homelab services tour 2026](https://technotim.com/posts/homelab-services-tour-2026/)
