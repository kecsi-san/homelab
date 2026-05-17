---
title: "013 — Forgejo Actions Runner with Docker-in-Docker"
type: adr
status: accepted
scope: [k8s]
created: 2026-05-17
updated: 2026-05-17
tags: [forgejo, ci-cd, runner, docker-in-docker, actions]
---

# 013 — Forgejo Actions Runner with Docker-in-Docker

## Status

Accepted

## Context

Forgejo Actions requires a **runner** — an agent that polls the Forgejo instance for
queued jobs and executes them. Forgejo Actions jobs are defined in YAML workflows
(GitHub Actions-compatible syntax). Most real-world CI jobs require Docker: building
container images, running service containers, or executing jobs inside a specified
Docker image (`runs-on: ubuntu-latest` with `container:` directives).

The homelab k8s cluster runs Forgejo Actions with the following requirements:
- **Docker image builds**: CI pipelines must be able to build and push OCI images to
  the Forgejo container registry
- **Job isolation**: each job runs in a fresh Docker container; no state bleeds between
  jobs
- **Kubernetes-native**: runner runs as a Deployment; no VMs or host-level Docker daemon
- **Persistent registration**: runner registration state (`.runner` file with token)
  must survive pod restarts without re-registering
- **Act runner**: Forgejo's official runner (`forgejo-runner`) based on `act`

## Decision

Deploy **Forgejo act_runner** (`code.forgejo.org/forgejo/runner:12.10.1`) as a
Kubernetes Deployment with a **Docker-in-Docker (DinD) sidecar**:

**Pod structure:**
```
Pod: forgejo-runner
├── Init: init-data       (busybox; chmod 777 /data — fixes PVC root ownership)
├── Init: register        (forgejo-runner; registers .runner file if absent)
├── Container: runner     (forgejo-runner daemon; waits for DinD, then starts)
└── Container: dind       (docker:27-dind; Docker daemon on tcp://localhost:2375)
```

**Key design decisions:**

1. **DinD sidecar over host Docker socket**: The k8s nodes do not run Docker
   (they run containerd via Kubespray); mounting `/var/run/docker.sock` is not
   possible. DinD provides a self-contained Docker daemon per pod.

2. **TCP (not TLS) DinD**: `DOCKER_TLS_CERTDIR=""` on the DinD container disables
   TLS; the Docker daemon listens on `tcp://localhost:2375`. Acceptable because
   the connection is pod-local (loopback only; not exposed outside the pod).

3. **Wait loop for DinD readiness**: The runner container uses a `wget` ping loop
   before starting the daemon — DinD takes ~2 seconds to initialize, and the runner
   image is Alpine-based (no `docker` CLI available to use `docker info`):
   ```sh
   until wget -qO- http://localhost:2375/_ping 2>/dev/null | grep -q OK; do
     echo "waiting for docker daemon..."
     sleep 2
   done
   ```

4. **Persistent PVC for registration**: The `.runner` file (registration state) is
   stored on a 1 Gi Longhorn PVC at `/data`. An init container (`init-data`) runs
   `chmod 777 /data` as root because fresh Longhorn PVCs are owned by `root:root`
   with mode 755; the runner runs as a non-root user and cannot write without the
   permission fix. A second init container (`register`) handles first-time registration
   with `workingDir: /data` (the `forgejo-runner register` binary writes `.runner`
   to the process CWD, not a configurable path).

5. **`Recreate` rollout strategy**: Not currently set (runner is a single replica
   Deployment) but should be used if replica count increases to avoid double registration
   attempts on the same PVC.

**Registration:**
- Instance-level runner registered at `https://forgejo.kecskemethy.org`
- Labels: `ubuntu-latest:docker://node:20-bookworm,self-hosted:docker://node:20-bookworm`
- Registration token stored as SealedSecret in `forgejo-runner` namespace
- Runner config (capacity: 2 concurrent jobs, workdir: `/data/workspaces`) in a ConfigMap

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| **Host-mode runner (on a VM/bare-metal)** | Would require a dedicated VM or installing the runner agent directly on a k8s node; not cloud-native; harder to manage lifecycle (version updates, restarts) via GitOps; conflates the CI agent with the cluster node |
| **Kubernetes executor (act_runner + k8s driver)** | Forgejo runner can spawn each job as a new Pod (true k8s-native isolation); however, this requires RBAC permissions for the runner to create pods in a namespace; job startup latency is higher (pod scheduling overhead); less mature than DinD in the Forgejo community |
| **Docker socket from host** | Not possible: k8s nodes use containerd, not Docker; no `/var/run/docker.sock`; even on Docker-based nodes this is a security risk (host root access via socket) |
| **Podman-in-Pod** | Rootless container builds without DinD; however, Forgejo act_runner's Docker integration is tested primarily against Docker; Podman socket compatibility has edge cases; less documentation available for this combination |
| **External runner (on hppd600g6 or workstation)** | Runner outside the cluster; simpler Docker access (host Docker daemon); however, requires network connectivity from Forgejo to the external host; harder to manage in GitOps; the NFS/backup host is not a CI machine |

## Consequences

**Positive:**
- Full Docker support in CI jobs: `docker build`, `docker push` to the Forgejo
  registry, multi-stage builds, service containers — all work as expected
- Registration is idempotent: the `init-data` + `register` init container pattern
  means the runner pod can restart without creating duplicate registrations in Forgejo
  (`.runner` file presence check prevents re-registration)
- GitOps-managed: the runner Deployment, ConfigMap, PVC, and SealedSecret are all
  committed to Git; ArgoCD syncs them; no manual SSH to node required
- Acts as `ubuntu-latest` and `self-hosted`: existing GitHub Actions workflows that
  specify `runs-on: ubuntu-latest` work unchanged when mirrored to Forgejo

**Negative / Trade-offs:**
- **Privileged container**: DinD requires `privileged: true`; this gives the DinD
  container full Linux capabilities and the ability to mount filesystems; it is a
  security risk if the runner executes untrusted code — acceptable in a homelab with
  known-trusted repos
- **TCP DinD without TLS**: The Docker daemon is accessible at `tcp://localhost:2375`
  within the pod; another container in the same pod could connect to it; since the pod
  has only two containers (runner + dind) and both are trusted, this is acceptable but
  would be a concern in a multi-tenant environment
- **Longhorn PVC permissions**: Fresh Longhorn PVCs have `root:root` ownership with
  mode 755; the init container workaround (`chmod 777`) is a patch, not a fix —
  Longhorn does not support `fsGroup` at the StorageClass level; a proper fix would
  be configuring `securityContext.fsGroup` in the pod spec (tried; inconsistent results
  with Longhorn RWO volumes)
- **Offline runner accumulation**: Early iterations (before PVC-backed persistence)
  re-registered on every pod restart, accumulating offline runners in the Forgejo UI;
  these must be deleted manually; the PVC fix prevents future accumulation
- Docker image pull latency: DinD starts with an empty image cache on each pod
  creation; first-run jobs pull base images from scratch; this can add minutes to
  cold-start CI times on slow connections
