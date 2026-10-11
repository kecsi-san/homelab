# Homelab infrastructure map

This folder holds the infrastructure map of the homelab: how the LAN, the two Kubernetes clusters, the AWS edge node and Cloudflare connect, and which services run where. The current version is v0.3, shown in the [root README](../../README.md#-infrastructure-map).

![Infrastructure map v0.3](homelab-architecture-v0.3-black.drawio.png)

## Folder contents

| File | What it is |
|------|------------|
| `homelab-architecture-v0.3-black.drawio` | Current map. Dark, One Dark Pro palette, block arrows between the big boxes. Open it in [diagrams.net](https://app.diagrams.net) or the draw.io desktop app. |
| `homelab-architecture-v0.3-black.drawio.png` | PNG preview of v0.3, used by the READMEs. |
| `homelab-architecture-v0.2-black.drawio` | Same content as v0.3, but traffic flows are real double-line connectors with right-angle routing instead of block arrows. |
| `homelab-architecture-v0.2-black.drawio.png` | PNG preview of the connector variant. |
| `homelab-architecture-drawio.py` | Generator for both `.drawio` files. Every box and arrow is placed by hand in the script. |
| `homelab-architecture-v0.2-black.py` / `.png` | The earlier dark version, made with the Python [`diagrams`](https://diagrams.mingrammer.com/) library. Not updated since the draw.io work, so its colors and layout are older. |
| `homelab-architecture-v0.1-light.py` / `.png` | The first version (light mode, `diagrams` library). Kept for comparison. |
| `icons/` | About 70 PNG logos used by the diagrams. |

## How to read the map

- **Box colour is the network zone.** The LAN is blue and the Kubernetes cluster cyan. AWS is yellow, Cloudflare orange and the WSL2 workstation with its k3s cluster green. Tooling is dark grey, and planned items are light grey in a dashed box.
- **Arrow colour is the flow type.** Direct traffic is light brown, Cloudflare traffic light yellow, secrets and mail relay pastel rose. Backups are light grey and GitOps sync mid grey. A legend at the bottom of the map lists them.
- **Logos mark services.** Zone headers carry OS or vendor logos (Debian, Windows 11, Kubernetes, AWS and so on).
- **The LAN is flat.** There are no VLANs yet, so the colors show network zones, not VLAN IDs. VLAN segmentation is listed under "Planned" on the map.
- Only hostnames and private IPs appear on the map. There are no secrets or personal identifiers, because the repo is public.

## Regenerating the draw.io files

```bash
python3 docs/homelab/homelab-architecture-drawio.py          # builds both variants
python3 docs/homelab/homelab-architecture-drawio.py block    # v0.3 only
python3 docs/homelab/homelab-architecture-drawio.py link     # v0.2 only
```

The script needs only the Python standard library. The logos are embedded into the `.drawio` files as data URIs, so each file is self-contained, which is also why they are about 1.2 MB each.

The palette and flow colours are constants at the top of the script (`BG`, `ZONES`, `FLOW`). Layout numbers are plain coordinates further down.

The `.drawio.png` previews are not produced by the script. They are screenshots of the diagram in the draw.io viewer, trimmed and given a small border. Regenerate them after any change to the `.drawio` files, or export a PNG from diagrams.net.

The two older Python versions need the `diagrams` library and Graphviz:

```bash
source ~/.venv/devops/bin/activate
python3 docs/homelab/homelab-architecture-v0.2-black.py
```

## Icons

Logos came from the open icon libraries [dashboard-icons](https://github.com/homarr-labs/dashboard-icons), [selfh.st/icons](https://selfh.st/icons/) and [simple-icons](https://simpleicons.org/). A few came from CNCF artwork or the projects' own repositories (kube-vip, external-dns, rspamd, Kubespray). Thumbsup uses its GitHub organisation avatar.

Some services have no public logo, so their icons were drawn by hand in the same flat style: VolSync, Sealed Secrets, OpenDMARC, Postscreen, certbot, the AWS SSM agent and Route53. Kromgo uses the favicon from its own ConfigMap. Swap any of these for a real logo by replacing the file in `icons/` (same name, PNG) and regenerating.

## History

| Date | Change |
|------|--------|
| 2026-05-15 | Docs reorganised into subfolders; the first diagram (v0.1, light) moved here. |
| 2026-10-11 | v0.2 (dark, Python `diagrams`) with network flow, and the first logo set. Inspired by an infrastructure map seen on r/homelab. |
| 2026-10-11 | Rebuilt as draw.io files: v0.2 with double-line connectors, v0.3 with block arrows between zones. Zones, flows and a legend added. |
| 2026-10-11 | AWS and EC2 boxes switched from text lists to icon cards. One Dark Pro palette, larger text, and a frame around the whole map. |
| 2026-10-11 | Logo prefixes in zone headers, and the title gets an icon. |

## Ideas for later

- Real logos for the hand-drawn icons, if the projects publish any.
- Sync the Python v0.2 version with the draw.io colors, or retire it.
- Replace the remaining text list boxes (Clients, router role, kube-vip addresses, "Also planned") with icon cards.
- Redraw the map once VLANs and the IPAM service (NetBox) are deployed, using VLAN colours.
