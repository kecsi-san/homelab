# configure_k8s-auto-uncordon

Installs a systemd timer + oneshot service on each `kube_control_plane` node
that uncordons every cluster node a few minutes after boot. Companion to
`playbooks/shutdown-k8s.yml`, which cordons all nodes before a graceful
power-off. Cordon state survives a reboot, so without this the cluster
would come back up with every node still marked unschedulable.

## What it does

- Templates `/usr/local/bin/uncordon-k8s-nodes.sh`: loops every node from
  `kubectl get nodes`, `kubectl wait --for=condition=Ready` on each one
  individually (per-node timeout, not cluster-wide), then uncordons it
- Templates a `uncordon-k8s-nodes.service` (oneshot, `After=kubelet.service`)
  and a `uncordon-k8s-nodes.timer` (`OnBootSec=`)
- Enables and starts the timer

Per-node waiting is deliberate: a genuinely stuck node stays cordoned
instead of blocking the healthy ones from being uncordoned.

## Variables

| Variable | Default | Description |
|----------|---------|--------------|
| `auto_uncordon_boot_delay` | `"180"` | Delay after boot before the uncordon attempt starts (systemd `OnBootSec=` syntax) |
| `auto_uncordon_node_ready_timeout` | `"300s"` | Per-node wait timeout for it to report `Ready` before giving up on that node (kubectl duration syntax) |

## Usage

Wired into `post-k8s.yml`, scoped to `kube_control_plane` only (the script
needs `/etc/kubernetes/admin.conf`, which only exists on control-plane
nodes):

```yaml
- name: Configure auto-uncordon timer
  ansible.builtin.import_role:
    name: configure_k8s-auto-uncordon
  tags:
    - auto-uncordon
```

## Notes

- `playbooks/uncordon-k8s.yml` is the manual fallback companion: run it if
  you don't want to wait for the timer, or the timer failed and cordon state
  is stuck.
- The script uses `KUBECONFIG=/etc/kubernetes/admin.conf` directly rather
  than a user kubeconfig, since it runs as a systemd service with no
  interactive user session.
- `kubectl uncordon` failures are swallowed (`|| true`) per-node so one
  stuck node doesn't abort the loop for the rest.
