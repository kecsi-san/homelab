# configure_k8s-image-prune

Installs a systemd timer and a oneshot service on each kube node that removes
container images no container refers to. Kubelet's own image garbage collection
only starts at 85% disk use. Our nodes sit between 20% and 60%, so old image
versions from every upgrade stay on disk (one node held 51 GB of them).

## What it does

- Templates `/usr/local/bin/k8s-image-prune.sh`, which runs `crictl rmi --prune`
  and logs how many images and how many MiB of `/var` it freed
- Templates `k8s-image-prune.service` (oneshot, `After=containerd.service kubelet.service`,
  low CPU and IO priority) and `k8s-image-prune.timer`
- Enables and starts the timer

`crictl rmi --prune` only removes images that no container uses, running or
exited. Images behind running pods are never touched.

## When it runs

The timer is relative to boot, not to the calendar:
`OnBootSec=45min` plus `OnUnitActiveSec=1w`, with a random spread of 10 minutes.

- On a node that is started now and then (for example only at the weekend),
  it prunes once, 45 minutes after boot, when pods have come back and pulled
  what they need. A calendar timer with `Persistent=true` would fire straight
  after boot instead, while images are briefly unreferenced.
- On a node that stays up for weeks, it repeats every week.
- The script keeps a stamp file (`/var/lib/k8s-image-prune/last-run`) and skips
  the run if the last one was less than 6 days ago, so several reboots in one
  week prune only once.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `image_prune_boot_delay` | `"45min"` | Delay after boot before the first prune (systemd `OnBootSec=` syntax) |
| `image_prune_interval` | `"1w"` | Repeat interval while the node stays up (`OnUnitActiveSec=`) |
| `image_prune_random_delay` | `"10min"` | Random spread so the nodes do not prune at the same moment |
| `image_prune_min_age_days` | `6` | Skip the run if the last successful prune is newer than this |

## Usage

Wired into `post-k8s.yml` for the `kube` group:

```yaml
- name: Configure container image prune timer
  ansible.builtin.import_role:
    name: configure_k8s-image-prune
  tags:
    - image-prune
```

To prune once right now on a node, run `sudo systemctl start k8s-image-prune.service`
(delete `/var/lib/k8s-image-prune/last-run` first if it ran within 6 days).
Check the result with `journalctl -u k8s-image-prune.service`.

## Notes

- `crictl` must be at `/usr/local/bin/crictl`, where Kubespray puts it. The service
  has a `ConditionPathExists` on it and does nothing without it.
- A pod rescheduled to a node later pulls its image again. Images served from the
  cluster's own Forgejo registry need that registry to be up at that moment.
