---
title: "002 — Kubespray as k8s Cluster Provisioner"
type: adr
status: accepted
scope: [k8s, ansible]
created: 2026-04-01
updated: 2026-05-17
tags: [kubernetes, kubespray, provisioner, ansible]
---

# 002 — Kubespray as k8s Cluster Provisioner

## Status

Accepted

## Context

The k8s cluster runs on 4 bare-metal nodes (HP EliteDesk/ProDesk mini PCs) with no
cloud provider, no managed control plane, and no PXE/IPMI infrastructure. The provisioner
must handle:

- Multi-control-plane HA setup (3 control-plane nodes + 1 worker)
- kube-vip for VIP-based API server load balancing
- Pluggable CNI (initially Calico, later Cilium)
- Ansible-based workflow (fits the existing homelab automation stack)
- Idempotent re-runs for node configuration and upgrades
- Full reset capability for cluster rebuilds

The cluster has been rebuilt multiple times during homelab evolution (typical full
rebuild: reset ~4 min, provision ~21 min, post-setup ~2 min = ~27 min total).

## Decision

Use **Kubespray** (`kubernetes-sigs/kubespray`, release-2.31 branch) via the
`kubernetes-sigs.kubespray` Ansible collection. Kubespray is invoked from the existing
Ansible playbook structure alongside custom roles.

Key configuration:
- `kube_version: v1.35.4`
- `kube_network_plugin: cilium` (migrated from calico in ADR-003)
- kube-vip for API VIP at `api.k8s.<domain>:6443`
- 3-node etcd cluster co-located with control-plane nodes

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| **kubeadm bare** | Would require writing all the HA, etcd, and upgrade logic manually; Kubespray already wraps kubeadm with battle-tested Ansible |
| **k0s** | Simpler but less flexible CNI support; smaller community; fewer Ansible integration points; would require learning a new tool ecosystem |
| **RKE2** | Rancher-focused; pulls in Rancher-specific defaults; heavier; the homelab does not use Rancher's management plane |
| **Talos Linux** | Immutable OS is a significant paradigm shift; no SSH, declarative API only; high learning curve; existing Ansible workflow becomes irrelevant; interesting for the future but not now |
| **k3s on bare metal** | No built-in multi-control-plane HA; networking is simpler but less production-representative; reserved for the local dev cluster (see ADR-001) |

## Consequences

**Positive:**
- Kubespray composes well with existing Ansible playbooks; the same `inventory/hosts`
  and `group_vars/` structure serves both Kubespray and custom roles
- kube-vip integration is built-in; no separate load balancer required for the API
- Full reset (`reset-k8s.yml`) and idempotent re-provision (`k8s.yml`) enable rapid
  cluster rebuilds during infrastructure evolution
- Multi-CNI support made the Calico → Cilium migration a config change + rebuild rather
  than a manual migration

**Negative / Trade-offs:**
- Kubespray has a steep learning curve; its `group_vars/` structure is extensive and
  overlaps with custom Ansible vars in non-obvious ways
- Upgrades between Kubernetes minor versions require switching Kubespray release
  branches, which occasionally introduces breaking changes
- Cluster rebuilds require restoring the SealedSecrets encryption key manually
  (step 5 of the rebuild runbook in `docs/ansible/k8s-homelab.md`)
- Firefox HSTS cache must be cleared after rebuilds (documented in the rebuild runbook)
