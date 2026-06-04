---
title: "003 — Cilium CNI (Migration from Calico)"
type: adr
status: accepted
scope: [k8s]
created: 2026-05-04
updated: 2026-05-17
tags: [cni, cilium, calico, networking, ebpf]
---

# 003 — Cilium CNI (Migration from Calico)

## Status

Accepted

## Context

The cluster launched with **Calico** as the CNI plugin (the Kubespray default). Calico
is a mature, widely-used CNI with solid network policy support. Over time, the following
limitations became relevant:

- **No native observability**: Calico has no equivalent to Cilium's Hubble — understanding
  pod-to-pod traffic required external tooling or tcpdump
- **iptables-based**: Calico uses iptables/ipvs for packet processing; as pod count grows
  this becomes a scalability bottleneck (O(n) iptables rules)
- **No built-in load balancer**: external load balancing is handled by kube-proxy / iptables
- **Community momentum**: Cilium has significantly overtaken Calico in terms of active
  development, CNCF graduation, and adoption in production environments

The migration required a full cluster rebuild (in-place CNI switching is unsupported in
Kubespray; Calico and Cilium cannot safely coexist during transition). The rebuild plan
was documented at `docs/research/rebuild_cilium_migration_plan.md`.

## Decision

Migrate to **Cilium** (via Kubespray's `kube_network_plugin: cilium`) with:

- **Hubble** observability enabled (in-cluster metrics + UI)
- **kube-proxy replacement** mode (`kubeProxyReplacement: true`) — Cilium replaces
  kube-proxy entirely using eBPF
- **eBPF-based dataplane** — kernel-level packet processing without iptables

Cilium is deployed via Kubespray's built-in Cilium support; no separate Helm chart
or CRD management required for the CNI itself.

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| **Calico (keep)** | No native observability; iptables scaling limits; falling behind Cilium in community and features |
| **Flannel** | Simpler but feature-poor; no network policies; no observability; designed for simplicity not capability |
| **Weave Net** | Development effectively stopped (acquired by Weaveworks, company shut down 2023); not a viable long-term choice |
| **Antrea** | VMware-backed; good features but smaller community than Cilium; VMware acquisition uncertainty |

## Consequences

**Positive:**
- **Hubble** provides real-time pod-to-pod traffic visibility without additional tooling;
  `hubble observe` and the Hubble UI give network-level debugging that Calico never offered
- eBPF-based kube-proxy replacement significantly reduces the iptables rule count and
  improves network performance at scale
- Cilium's built-in network policies are more expressive than Calico's
- CNCF graduated project with strong vendor support (Isovalent/Cisco) and large community

**Negative / Trade-offs:**
- Migration required a full cluster rebuild (~27 minutes); all PVCs and workloads were
  temporarily offline
- The SealedSecrets encryption key must be restored after every rebuild (critical step
  in the rebuild runbook)
- Cilium requires a relatively modern kernel (≥5.10); all 4 nodes run Debian 13 which
  satisfies this
- Hubble adds a small resource overhead (DaemonSet + Relay pod); acceptable on
  the current 4-node hardware
