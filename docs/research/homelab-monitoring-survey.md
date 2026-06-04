# Monitoring Stacks in Popular Homelab Repos — Survey

**Date:** 2026-05-28  
**Method:** Direct GitHub repo tree inspection + web search. Only verified setups are listed.

---

## Repo Survey

| Repo | Stars | Metrics | Logs | Uptime/Status | Notes |
|------|-------|---------|------|---------------|-------|
| [khuedoan/homelab](https://github.com/khuedoan/homelab) | 9.3k | Prometheus + Grafana | Loki | — | Most-starred pure-k8s homelab; Cilium/Hubble for network observability |
| [onedr0p/home-ops](https://github.com/onedr0p/home-ops) | 2.8k | kube-prometheus-stack + grafana-operator | VictoriaLogs | Gatus | Widely copied template; Kromgo for badge metrics; Pushover alerts; snmp-exporter, smartctl-exporter, blackbox-exporter |
| [bjw-s-labs/home-ops](https://github.com/bjw-s-labs/home-ops) | 834 | kube-prometheus-stack + grafana-operator | VictoriaLogs | Gatus | Near-identical to onedr0p; silence-operator, smartctl-exporter, blackbox-exporter |
| [lisenet/kubernetes-homelab](https://github.com/lisenet/kubernetes-homelab) | 502 | Prometheus + Grafana + Alertmanager | Loki + Promtail | — | etcd, HAProxy, Bind DNS, MikroTik exporters; Kiali for Istio; Slack alerting |
| [szinn/k8s-homelab](https://github.com/szinn/k8s-homelab) | 296 | kube-prometheus-stack | Loki + Grafana Alloy | Gatus | Alloy replaces Promtail; Gatus runs on a Raspberry Pi (out-of-band monitoring) |
| [joryirving/home-ops](https://github.com/joryirving/home-ops) | 216 | kube-prometheus-stack + grafana-operator | VictoriaLogs | Gatus | Karma (Alertmanager UI), promxy (multi-cluster aggregator), hoymiles-exporter (solar), nut-exporter (UPS), unpoller (UniFi) |
| [budimanjojo/home-cluster](https://github.com/budimanjojo/home-cluster) | 246 | kube-prometheus-stack | VictoriaLogs | Gatus | Fluent Bit for log forwarding; silence-operator |
| [gruberdev/homelab](https://github.com/gruberdev/homelab) | 248 | kube-prometheus (kube-prometheus, not KPS) | — | Uptime Kuma | One of the few repos using Uptime Kuma over Gatus |
| [mchestr/home-cluster](https://github.com/mchestr/home-cluster) | 163 | Prometheus + Grafana | VictoriaLogs + Fluent Bit | Gatus | Pushover alerts |
| [nicolerenee/infra](https://github.com/nicolerenee/infra) | 108 | **VictoriaMetrics** + Grafana | VictoriaLogs | Gatus | Lone outlier: drops Prometheus entirely for VictoriaMetrics as primary backend; silence-operator |
| TechnoTim (YouTube/docs) | 1.2k (docs repo) | kube-prometheus-stack | — | — | Recommends KPS in tutorials; most-referenced homelab k8s video content |
| [rcourtman/Pulse](https://github.com/rcourtman/Pulse) | 5.8k | Built-in (Proxmox/Docker) | — | Built-in | Not a k8s GitOps repo; trending standalone dashboard for Proxmox+Docker homelabs |

---

## Patterns and Trends

### kube-prometheus-stack is the de facto standard
Every k8s GitOps homelab repo surveyed uses it as the metrics foundation. No repo replaced Prometheus with a different scraper except `nicolerenee/infra` (lone VictoriaMetrics-as-primary outlier). The chart bundles Prometheus Operator, Alertmanager, node-exporter, kube-state-metrics, and pre-built dashboards.

### grafana-operator is replacing KPS-bundled Grafana
`onedr0p`, `bjw-s`, `joryirving`, `szinn`, and `budimanjojo` all run Grafana via the [grafana-operator](https://github.com/grafana/grafana-operator) rather than the Grafana instance included with kube-prometheus-stack. This enables declarative `GrafanaDashboard` and `GrafanaDatasource` CRDs committed to Git — a better GitOps fit.

### VictoriaLogs is displacing Loki for log storage
`onedr0p`, `bjw-s`, `joryirving`, `budimanjojo`, `mchestr`, and `nicolerenee` all use [VictoriaLogs](https://docs.victoriametrics.com/victorialogs/). Loki remains in `szinn` and `lisenet` but is no longer the default in the most-followed repos. VictoriaLogs is a single binary, uses significantly less RAM than Loki, and is simpler to operate.

### Gatus has standardised as the uptime/status-page tool in k8s GitOps
Virtually every GitOps repo uses Gatus over Uptime Kuma. Gatus is declarative (config in YAML/ConfigMap), GitOps-native, and supports external probe hosts. Uptime Kuma dominates non-k8s Docker homelabs but is database-backed and harder to manage as code.

### Kromgo + README/dashboard badges are near-universal
Almost all template repos expose selected Prometheus queries via Kromgo as badge-friendly HTTP endpoints used in READMEs and Homepage tiles.

### Beszel — trending but not k8s-native
[henrygd/beszel](https://github.com/henrygd/beszel) (16k+ stars) is gaining momentum in `r/homelab` as a lightweight node/container monitor but has no Kubernetes pod-level support. Appears in Proxmox/Docker homelabs only.

---

## Implications for This Repo

| Finding | Action |
|---------|--------|
| kube-prometheus-stack confirmed as right choice | No change needed |
| grafana-operator pattern worth adopting | Consider over KPS-bundled Grafana when implementing |
| VictoriaLogs worth adding to plan | Cheaper than Loki; add as log storage alongside metrics |
| Gatus already deployed | Ahead of most repos on uptime monitoring |
| Kromgo already in TODO | Confirmed community standard |
| Beszel | Not relevant — k8s-native metrics covered by KPS |

---

## Sources

- [onedr0p/home-ops](https://github.com/onedr0p/home-ops)
- [bjw-s-labs/home-ops](https://github.com/bjw-s-labs/home-ops)
- [khuedoan/homelab](https://github.com/khuedoan/homelab)
- [joryirving/home-ops deepwiki](https://deepwiki.com/joryirving/home-ops/4.2-grafana-and-dashboards)
- [szinn/k8s-homelab](https://github.com/szinn/k8s-homelab)
- [budimanjojo/home-cluster](https://github.com/budimanjojo/home-cluster)
- [gruberdev/homelab](https://github.com/gruberdev/homelab)
- [lisenet/kubernetes-homelab](https://github.com/lisenet/kubernetes-homelab)
- [mchestr/home-cluster](https://github.com/mchestr/home-cluster)
- [nicolerenee/infra](https://github.com/nicolerenee/infra)
- [rcourtman/Pulse](https://github.com/rcourtman/Pulse)
- [henrygd/beszel](https://github.com/henrygd/beszel)
- [Spectro Cloud: Choosing the right k8s monitoring stack 2026](https://www.spectrocloud.com/blog/choosing-the-right-kubernetes-monitoring-stack)
