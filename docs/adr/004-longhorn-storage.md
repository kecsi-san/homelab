---
title: "004 — Longhorn for Distributed Block Storage"
type: adr
status: accepted
scope: [k8s]
created: 2026-04-01
updated: 2026-05-17
tags: [storage, longhorn, persistent-volumes, csi]
---

# 004 — Longhorn for Distributed Block Storage

## Status

Accepted

## Context

Kubernetes workloads with persistent state (Forgejo, Authentik, Outline, CNPG, ntfy,
gatus, mealie) require a `StorageClass` that provides `PersistentVolumes`. The homelab
nodes do not have a SAN, dedicated NVMe arrays, or cloud-provided block storage. Options
are limited to what can be provisioned from the existing local disks on each node.

The NFS server on `hppd600g6` (a 100 GB LV at `/backups`) exists but is used for
backups, not for primary storage — using it for PVCs would create a single point of
failure (all storage on one node).

Requirements:
- **Multi-node redundancy**: survive the loss of one node without data loss
- **ReadWriteOnce** block semantics for stateful apps (databases, app data directories)
- **Dynamic provisioning**: `PVC` → automatic `PV` binding
- **Kubernetes-native**: CSI driver, VolumeSnapshot support for VolSync
- **Manageable**: visible UI, no distributed systems PhD required

## Decision

Use **Longhorn** as the default `StorageClass` across the k8s cluster:

- Deployed via Helm (`longhorn/longhorn` chart) managed by ArgoCD
- Default replica count: 2 (data replicated across 2 nodes)
- Storage reserved: 2 GB per disk (`storageReserved`)
- Over-provisioning: 100% (`storageOverProvisioningPercentage`)
- Minimum available: 25% (`storageMinimalAvailablePercentage`)
- Each node contributes `/var` (100 GB LV, ~79–83 GB free post-setup)

Longhorn volumes are used by: CNPG PVCs, Forgejo data, Authentik Redis, Outline data,
ntfy, gatus, mealie, Longhorn-backed VolSync snapshots.

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| **NFS (hppd600g6)** | Single point of failure; no block semantics (ReadWriteMany only); poor performance for databases; backup node should not be primary storage |
| **local-path (k3s default)** | No replication; node-local only; PV is lost if the node is lost; used only on k3s where single-node is acceptable |
| **OpenEBS** | More complex operator model; multiple storage engines to choose from (Mayastor, cStor, Jiva); less beginner-friendly UI |
| **Rook/Ceph** | Powerful but heavy; requires dedicated OSD nodes or disks; operational complexity is high for a homelab; 3+ node minimum for quorum; significant RAM overhead per OSD |
| **TopoLVM** | Excellent performance (LVM-based thin provisioning) but no built-in replication; data on one node only; similar to local-path in failure characteristics |

## Consequences

**Positive:**
- Longhorn UI at `longhorn.kecskemethy.org` provides a clear view of volume health,
  node storage usage, and replica placement — invaluable for debugging
- VolumeSnapshot support enables VolSync `Clone` copy method for backup source snapshots
- Replica count per volume is adjustable (currently 2); can increase to 3 for
  more critical volumes
- iSCSI-based; standard CSI interface; works with any CSI-compatible tool
- `longhornctl` installed on all nodes for offline diagnostics

**Negative / Trade-offs:**
- Longhorn adds ~300–400 MB RAM overhead per node (manager + engine DaemonSets)
- Write amplification with 2 replicas: every write hits 2 nodes, halving effective
  write throughput vs local storage
- The Longhorn UI is protected by Authentik forwardAuth (deployed 2026-05-16); a
  broken Authentik deployment temporarily blocks Longhorn UI access
- VolumeSnapshot with `copyMethod: Clone` requires that the source volume is not
  mounted by a pod using `ReadWriteOnce` — VolSync handles this via a snapshot
  intermediate; `copyMethod: Snapshot` requires a configured Longhorn backup target
  which is not set up (using restic REST server instead)
- Longhorn upgrades occasionally require specific upgrade paths (minor version must
  be upgraded sequentially; skipping versions is unsupported)
