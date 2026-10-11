"""
Homelab infrastructure map as a draw.io file (dark mode), hand-placed layout.

Run:  python3 docs/homelab/homelab-architecture-drawio.py [link|block]
Out:  docs/homelab/homelab-architecture-v0.2-black.drawio   link  : double-line connectors
      docs/homelab/homelab-architecture-v0.3-black.drawio   block : block arrows between zones
      (no argument builds both; open in draw.io / diagrams.net)

Same content and conventions as homelab-architecture-v0.2-black.py (Python diagrams
version), but every box and arrow is placed by hand, so main traffic flows are real
double-line connectors (shape=link) with right-angle routing.

- Box colour = network zone; line colour = flow type (disjoint palettes, see LEGEND).
- Logos are embedded as data URIs (icons/*.png), so the file is self-contained.
- Services without a logo are bullet lists in "More" boxes.
- Hostnames and private IPs only; no secrets or personal identifiers.
"""

import base64
import subprocess
import sys
from html import escape
from pathlib import Path

HERE = Path(__file__).parent
ICONS = HERE / "icons"

if len(sys.argv) == 1:  # no mode given: build both variants in fresh processes
    for _m in ("link", "block"):
        subprocess.run([sys.executable, __file__, _m], check=True)
    sys.exit(0)
MODE = sys.argv[1]
assert MODE in ("link", "block"), "mode must be 'link' or 'block'"
OUT = HERE / ("homelab-architecture-v0.2-black.drawio" if MODE == "link" else "homelab-architecture-v0.3-black.drawio")

# One Dark Pro palette (Binaryify/OneDark-Pro)
BG, CARD, TEXT, MUTED = "#282c34", "#2c313a", "#c8ccd4", "#7f848e"
FRAME = "#21252b"
ZONES = {
    "lan": "#61afef",  # blue
    "pod": "#56b6c2",  # cyan
    "aws": "#e5c07b",  # yellow
    "cf": "#d19a66",  # orange
    "dev": "#98c379",  # green
    "tool": "#5c6370",  # comment grey
    "plan": "#abb2bf",  # light grey, always dashed
}
# Flow colours avoid the zone hues; One Dark has too few hues for a fully disjoint set, so
# the reds and greys are the only overlaps (plan/tooling boxes are grey, flows are lines).
FLOW = {"lan": "#c9a27e", "cf": "#f3e5a8", "secret": "#e8b4a8", "backup": "#abb2bf", "git": "#7f848e"}

CW, CH = 124, 104  # card size
PX, PY = 132, 112  # grid pitch
HEAD = 36  # zone header height

cells = []
ABS = {}  # id -> (abs_x, abs_y, w, h)
_n = [1]


def nid():
    _n[0] += 1
    return f"c{_n[0]}"


def icon_uri(name):
    data = (ICONS / f"{name}.png").read_bytes()
    return "data:image/png," + base64.b64encode(data).decode()


def add(cid, value, style, parent, x, y, w, h):
    px, py = (ABS[parent][0], ABS[parent][1]) if parent in ABS else (0, 0)
    ABS[cid] = (x, y, w, h)
    cells.append(
        f'<mxCell id="{cid}" value="{escape(value, quote=True)}" style="{style}" vertex="1" parent="{parent}">'
        f'<mxGeometry x="{x - px}" y="{y - py}" width="{w}" height="{h}" as="geometry"/></mxCell>'
    )
    return cid


def zone(title, key, x, y, w, h, parent="1", dashed=False, alpha=14):
    c = ZONES[key]
    style = (
        f"rounded=1;arcSize=3;html=1;whiteSpace=wrap;fillColor={c};fillOpacity={alpha};"
        f"strokeColor={c};strokeWidth=2;{'dashed=1;' if dashed else ''}verticalAlign=top;align=left;"
        f"spacingLeft=12;spacingTop=6;fontStyle=1;fontSize=16;fontColor={c};container=1;collapsible=0;"
    )
    return add(nid(), title, style, parent, x, y, w, h)


def card(title, sub, icon, x, y, parent="1", w=CW, h=CH, isize=52):
    label = f"<b>{escape(title)}</b>" + (f"<br><font color='{MUTED}'>{escape(sub)}</font>" if sub else "")
    style = (
        f"shape=label;html=1;whiteSpace=wrap;image={icon_uri(icon)};imageWidth={isize};imageHeight={isize};"
        f"imageAlign=center;imageVerticalAlign=top;verticalAlign=bottom;fillColor=none;strokeColor=none;"
        f"fontColor={TEXT};fontSize=12;spacingBottom=2;"
    )
    return add(nid(), label, style, parent, x, y, w, h)


def listbox(title, lines, key, x, y, w, parent="1", dashed=False):
    h = 28 + 15 * len(lines)
    body = f"<b>{escape(title)}</b><br>" + "<br>".join("• " + escape(t) for t in lines)
    style = (
        f"rounded=1;arcSize=10;html=1;whiteSpace=wrap;fillColor={CARD};strokeColor={ZONES[key]};"
        f"strokeWidth=1.5;{'dashed=1;' if dashed else ''}align=left;verticalAlign=middle;spacingLeft=10;"
        f"fontColor={TEXT};fontSize=12;"
    )
    return add(nid(), body, style, parent, x, y, w, h)


def grid(zid, items, cols, y_off=HEAD):
    """Place cards in a grid inside zone `zid`; items are (title, sub, icon)."""
    zx, zy, _, _ = ABS[zid]
    ids = []
    for i, (t, s, ic) in enumerate(items):
        if t is None:
            ids.append(None)
            continue
        ids.append(card(t, s, ic, zx + 12 + (i % cols) * PX, zy + y_off + (i // cols) * PY, zid))
    return ids


def zsize(n, cols, extra=0):
    rows = -(-n // cols)
    return cols * PX + 24, HEAD + rows * PY + extra + 16


def edge(src, dst, label="", flow="lan", main=False, points=(), exit_=None, entry=None, dashed=False):
    c = FLOW[flow]
    if main:
        # shape=link renders a true double line
        style = f"shape=link;html=1;width=7;strokeColor={c};endArrow=classic;endFill=1;endSize=8;"
    else:
        style = f"html=1;strokeColor={c};strokeWidth=2;endArrow=classic;endFill=1;{'dashed=1;' if dashed else ''}"
    style += "edgeStyle=orthogonalEdgeStyle;rounded=0;jettySize=0;"
    style += f"labelBackgroundColor={BG};fontColor={c};fontSize=12;"
    if exit_:
        style += f"exitX={exit_[0]};exitY={exit_[1]};exitDx=0;exitDy=0;"
    if entry:
        style += f"entryX={entry[0]};entryY={entry[1]};entryDx=0;entryDy=0;"
    pts = "".join(f'<mxPoint x="{x}" y="{y}"/>' for x, y in points)
    arr = f'<Array as="points">{pts}</Array>' if pts else ""
    cells.append(
        f'<mxCell id="{nid()}" value="{escape(label, quote=True)}" style="{style}" edge="1" parent="1" '
        f'source="{src}" target="{dst}"><mxGeometry relative="1" as="geometry">{arr}</mxGeometry></mxCell>'
    )


def arrow(text, flow, x, y, w, h, direction="south", double=False):
    """Block arrow between two big boxes. Text says what flows; it points at a zone, not a service."""
    c = FLOW[flow]
    shape = "doubleArrow" if double else "singleArrow"
    style = (
        f"shape={shape};direction={direction};html=1;whiteSpace=wrap;fillColor={c};strokeColor=none;"
        f"fontColor={BG};fontStyle=1;fontSize=12;arrowWidth=0.78;arrowSize=0.22;"
    )
    return add(nid(), text, style, "1", x, y, w, h)


def center_x(cid):
    x, _, w, _ = ABS[cid]
    return x + w / 2


# ================================================================== layout
# Vertical bands, top to bottom, with gaps between the big boxes that hold block arrows:
#   Internet band | arrows | Cloudflare + AWS zones | arrows | LAN (router box | arrow | k8s ...)
K = 170  # shift of everything inside the LAN below the router box (room for the router box + arrow)

add(nid(), "Homelab · infrastructure map", f"text;html=1;fontSize=34;fontStyle=1;fontColor={TEXT};align=left;", "1", 40, 14, 800, 44)

# ---- Public network: a wide band the arrows hang off
if MODE == "block":
    # v0.3: the band is just a big label; the arrows hang off its edges
    z_net = zone("", "tool", 120, 66, 2420, 134, alpha=10)
    add(nid(), "🌐&nbsp;&nbsp;Public network / Internet&nbsp;&nbsp;🌐",
        f"text;html=1;fontSize=44;fontStyle=1;fontColor={ZONES['plan']};align=center;verticalAlign=middle;",
        z_net, 120, 66, 2420, 134)
else:
    z_net = zone("Public network", "tool", 120, 66, 2420, 134, alpha=10)
    internet = card("Internet", "users · mail · Minecraft", "internet", 1245, 80, z_net, w=160, h=114, isize=64)

# ---- Cloudflare
w, h = zsize(4, 2, extra=96)
z_cf = zone("Cloudflare edge", "cf", 120, 290, w, h)
cf_ids = grid(
    z_cf,
    [
        ("Let's Encrypt", "DNS-01 certs", "lets-encrypt"),
        ("Cloudflare", "DNS · proxy · ECH", "cloudflare"),
        (None, None, None),
        ("Cloudflare Tunnel", "outbound QUIC", "cloudflared"),
    ],
    2,
)
listbox("Clients", ["Edge browser (LAN path)", "Firefox + WARP (Cloudflare path)", "Minecraft Bedrock (UDP 19132)"], "cf", 132, 290 + HEAD + 2 * PY + 4, w - 24, z_cf)
cf_bottom = 290 + h

# ---- AWS
z_aws = zone("AWS · single production edge node (Debian, Terraform-managed)", "aws", 1480, 290, 1060, 438)
w, h = zsize(12, 4)
z_ec2 = zone("EC2 · mail, web, secrets", "aws", 1500, 330, w, h, z_aws, alpha=18)
ec2 = grid(
    z_ec2,
    [
        ("Vault", "secrets KV", "hashicorp-vault"),
        ("Dovecot", "IMAPS", "dovecot"),
        ("Postfix", "SMTP", "postfix"),
        ("Apache2", "+ ModSecurity", "apache"),
        ("Rspamd", "spam · DKIM", "rspamd"),
        ("Duo", "SSH MFA (PAM)", "duo"),
        ("Unbound", "DNSSEC resolver", "unbound"),
        ("OpenDMARC", "inbound DMARC", "opendmarc"),
        ("Postscreen", "DNSBL filter", "postscreen"),
        ("certbot", "Route53 DNS-01", "certbot"),
        ("fail2ban", "", "fail2ban"),
        ("SSM agent", "rescue shell", "ssm-agent"),
    ],
    4,
)
w, h = zsize(4, 3)
z_awssvc = zone("AWS services", "aws", 2072, 330, 448, h, z_aws, alpha=18)
grid(
    z_awssvc,
    [
        ("AWS", "EC2 · EIP · SG", "aws"),
        ("WireGuard hub", "planned", "wireguard"),
        ("Route53", "DNS zones", "route53"),
        ("S3", "remote state", "amazon-s3"),
    ],
    3,
)
aws_bottom = 290 + 438

# ---- LAN
LAN_Y = 800
LAN_H = 1240
z_lan = zone("LAN · 192.168.1.0/24 · flat network, no VLANs yet", "lan", 40, LAN_Y, 2520, LAN_H, alpha=10)

# router box (edge of the LAN) with the arrow into the cluster beneath it
z_rt = zone("MikroTik router · 192.168.1.1", "lan", 1000, 850, 780, 140, z_lan, alpha=22)
router = card("MikroTik", "WAN edge", "mikrotik", 1012, 880, z_rt)
listbox("Router role", ["split-horizon DNS: *.<domain> → .101", "static records (prolion, backups, api VIP)", "dst-nat UDP 19132 → .110 · NTP source for all nodes"], "lan", 1366, 876, 400, z_rt)

# ---- k8s
z_k8s = zone("k8s · Kubespray 2.31 · Kubernetes 1.35 · Cilium", "pod", 130, 900 + K, 1490, 934, z_lan, alpha=12)
w, h = zsize(4, 4)
z_nodes = zone("Nodes (Debian)", "lan", 150, 940 + K, w, h, z_k8s, alpha=22)
grid(
    z_nodes,
    [
        ("hped800g5 · .18", "CP + etcd · i5-9500T · 32 GB", "kubernetes"),
        ("hped800g62 · .34", "CP + etcd · i5-10500T · 24 GB", "kubernetes"),
        ("hppd600g6 · .52", "CP + etcd · NFS + restic", "kubernetes"),
        ("hped800g61 · .36", "worker · i5-10500T · 16 GB", "kubernetes"),
    ],
    4,
)
card("kube-vip", "L2 VIPs", "kube-vip", 740, 950 + K, z_k8s)
vips = listbox("kube-vip virtual IPs (L2/ARP)", [".100  Kubernetes API (api.k8s.<domain>)", ".101  Traefik LoadBalancer", ".110  Minecraft Bedrock (UDP)"], "lan", 880, 950 + K, 380, z_k8s)

w, h = zsize(10, 4)
z_plat = zone("Platform", "pod", 150, 1150 + K, w, h, z_k8s, alpha=22)
plat = grid(
    z_plat,
    [
        ("cloudflared", "2 replicas", "cloudflared"),
        ("Traefik", "ingress", "traefik"),
        ("cert-manager", "per-service certs", "cert-manager"),
        ("Cilium", "CNI · eBPF", "cilium"),
        ("ArgoCD", "app-of-apps", "argo-cd"),
        ("Reloader", "", "reloader"),
        ("external-dns", "Cloudflare sync", "external-dns"),
        ("External Secrets", "→ Vault", "external-secrets"),
        ("Sealed Secrets", "encrypted secrets in git", "sealed-secrets"),
        ("pod-cleanup", "nightly CronJob", "kubernetes"),
    ],
    4,
)

w, h = zsize(6, 3)
z_id = zone("Identity & developer tools", "pod", 722, 1150 + K, w, h, z_k8s, alpha=22)
grid(
    z_id,
    [
        ("Authentik", "SSO / OIDC", "authentik"),
        ("Forgejo", "git · OCI · CI", "forgejo"),
        ("Forgejo runner", "Actions CI", "forgejo"),
        ("Backstage", "portal", "backstage"),
        ("Wiki.js", "wiki", "wiki-js"),
        ("Headlamp", "k8s UI", "headlamp"),
    ],
    3,
)
z_obs = zone("Observability", "pod", 1162, 1150 + K, w, h, z_k8s, alpha=22)
obs = grid(
    z_obs,
    [
        ("Prometheus", "", "prometheus"),
        ("Alertmanager", "", "alertmanager"),
        ("Grafana", "operator", "grafana"),
        ("kromgo", "status badges", "kromgo"),
        ("ntfy", "push alerts", "ntfy"),
        ("Gatus", "uptime", "gatus"),
    ],
    3,
)

w, h = zsize(5, 5)
z_data = zone("Data & storage", "pod", 150, 1560 + K, w, h, z_k8s, alpha=22)
data = grid(
    z_data,
    [
        ("CloudNativePG", "3× PostgreSQL", "cloudnativepg"),
        ("Garage", "S3", "garage"),
        ("Longhorn", "block storage", "longhorn"),
        ("VolSync", "backs up volumes to restic", "volsync"),
        ("restic REST", "hppd600g6 :8000", "restic"),
    ],
    5,
)
w, h = zsize(5, 5)
z_apps = zone("Apps", "pod", 854, 1560 + K, w, h, z_k8s, alpha=22)
grid(
    z_apps,
    [
        ("Minecraft", "Bedrock", "minecraft"),
        ("Mealie", "recipes", "mealie"),
        ("Glance", "dashboard", "glance"),
        ("Homepage", "start page", "homepage"),
        ("OpenCloud", "files", "opencloud"),
    ],
    5,
)

# ---- prolion / workstation / planned (right column of LAN)
z_pro = zone("prolion · 192.168.1.10 · Debian 13 file server · 7.3 TB /stuff array", "lan", 1660, 900 + K, 860, 170, z_lan, alpha=22)
grid(
    z_pro,
    [
        ("Jellyfin", "", "jellyfin"),
        ("Transmission", "", "transmission"),
        ("thumbsup", "photo gallery", "thumbsup"),
        ("Postfix", "→ EC2 mail relay", "postfix"),
    ],
    6,
)

z_ws = zone("Workstation · Windows 11 + WSL2 (192.168.1.25)", "dev", 1660, 1100 + K, 860, 330, z_lan, alpha=16)
grid(z_ws, [("Control node", "Ansible · kubectl", "ansible"), ("Windows 11", "desktop", "windows-11")], 2)
z_k3s = zone("k3s · single-node dev cluster", "dev", 1960, 1136 + K, 552, 276, z_ws, alpha=22)
grid(
    z_k3s,
    [
        ("k3s", "local-path storage", "k3s"),
        ("Traefik", "", "traefik"),
        ("Authentik", "", "authentik"),
        ("Homepage", "", "homepage"),
        ("Headlamp", "", "headlamp"),
        ("Forgejo", "scaled to 0", "forgejo"),
        ("Forgejo runner", "scaled to 0", "forgejo"),
        ("Wiki.js", "scaled to 0", "wiki-js"),
    ],
    4,
)

z_plan = zone("Planned", "plan", 1660, 1460 + K, 860, 250, z_lan, dashed=True, alpha=10)
grid(z_plan, [("IPAM (NetBox)", "IPs · VLANs · hosts", "netbox")], 3)
listbox("Also planned", ["VLAN segmentation", "Cilium LB-IPAM / BGP", "WireGuard spokes"], "plan", 1812, 1500 + K, 320, z_plan, dashed=True)

# ---- Built with + legend (below LAN)
BY = LAN_Y + LAN_H + 110  # extra gap holds the GitOps sync arrow
w, h = zsize(9, 9)
z_built = zone("Built and managed with", "tool", 40, BY, w, h, alpha=10)
grid(
    z_built,
    [
        ("Ansible", "host config", "ansible"),
        ("Terraform", "AWS · Vault", "terraform"),
        ("Helm", "chart installs", "helm"),
        ("Renovate", "version bumps", "renovate"),
        ("Kubespray", "cluster lifecycle", "kubespray"),
        ("Git", "", "git"),
        ("GitHub", "monorepo", "github"),
        ("just", "task runner", "just"),
        ("pre-commit", "yamllint", "pre-commit"),
    ],
    9,
)

z_leg = zone("Legend", "tool", 1300, BY, 1100, 250, alpha=10)


def legend(title, rows, x, w):
    body = f"<b>{title}</b><br>" + "<br>".join(f"<font color='{c}'>&#9632;</font>&nbsp; {escape(t)}" for c, t in rows)
    style = f"rounded=1;arcSize=6;html=1;whiteSpace=wrap;fillColor={CARD};strokeColor={ZONES['tool']};align=left;verticalAlign=middle;spacingLeft=10;fontColor={TEXT};fontSize=12;"
    add(nid(), body, style, z_leg, x, BY + HEAD, w, 190)


legend(
    "Zones (box colour)",
    [
        (ZONES["lan"], "LAN 192.168.1.0/24, flat, no VLANs yet"),
        (ZONES["pod"], "Kubernetes cluster (Cilium pod/service network)"),
        (ZONES["aws"], "AWS, single EC2 edge node"),
        (ZONES["cf"], "Cloudflare edge (DNS, Tunnel, WARP)"),
        (ZONES["dev"], "WSL2 workstation + k3s dev cluster"),
        (ZONES["plan"], "planned, not deployed (dashed box)"),
        (ZONES["tool"], "tooling / control node"),
    ],
    1312,
    520,
)


def sample_arrow(x, y, flow, direction="east", double=False, w=60, h=24):
    c = FLOW[flow]
    shape = "doubleArrow" if double else "singleArrow"
    style = f"shape={shape};direction={direction};html=1;fillColor={c};strokeColor=none;arrowWidth=0.7;arrowSize=0.35;"
    add(nid(), "", style, "1", x, y, w, h)


def sample_line(x, y, flow, double=False, w=60):
    c = FLOW[flow]
    style = (f"shape=link;width=6;" if double else "") + f"html=1;strokeColor={c};strokeWidth=2;endArrow=classic;endFill=1;"
    cells.append(
        f'<mxCell id="{nid()}" value="" style="{style}" edge="1" parent="1"><mxGeometry relative="1" as="geometry">'
        f'<mxPoint x="{x}" y="{y}" as="sourcePoint"/><mxPoint x="{x + w}" y="{y}" as="targetPoint"/></mxGeometry></mxCell>'
    )


def legend_flows(x, w):
    add(nid(), "<b>Flows</b>", f"rounded=1;arcSize=6;html=1;whiteSpace=wrap;fillColor={CARD};strokeColor={ZONES['tool']};align=left;verticalAlign=top;spacingLeft=10;spacingTop=6;fontColor={TEXT};fontSize=12;", "1", x, BY + HEAD, w, 190)
    if MODE == "block":
        rows = [
            ("arrow", "lan", "traffic entering the LAN directly (WAN, NAT)", {}),
            ("arrow", "cf", "traffic via Cloudflare (HTTPS, tunnel)", {}),
            ("arrow", "secret", "secrets and mail between LAN and AWS", {"double": True}),
            ("arrow", "git", "GitOps sync: GitHub → ArgoCD", {}),
            ("line", "backup", "backups (restic)", {}),
        ]
    else:
        rows = [
            ("line", "lan", "main traffic, direct (double line)", {"double": True}),
            ("line", "cf", "main traffic via Cloudflare (double line)", {"double": True}),
            ("line", "secret", "alerts", {}),
            ("line", "backup", "backups (restic)", {}),
            ("arrow", "git", "GitOps sync: GitHub → ArgoCD", {}),
        ]
    y = BY + HEAD + 30
    for kind, flow, text, kw in rows:
        if kind == "arrow":
            sample_arrow(x + 12, y - 2, flow, **kw)
        else:
            sample_line(x + 12, y + 10, flow, double=kw.get("double", False))
        add(nid(), escape(text), f"text;html=1;fontSize=12;fontColor={TEXT};align=left;verticalAlign=middle;", "1", x + 84, y, w - 96, 24)
        y += 26
    add(nid(), '"More" boxes list services without a logo', f"text;html=1;fontSize=12;fontColor={MUTED};align=left;verticalAlign=middle;", "1", x + 12, y + 2, w - 24, 20)


legend_flows(1852, 536)

# ================================================================== main flows
if MODE == "block":
    AW, AH = 190, 74
    cf_cx = 120 + (2 * PX + 24) / 2
    # Internet band -> Cloudflare / direct to router / AWS
    arrow("HTTPS via WARP", "cf", cf_cx - AW / 2, 206, AW, 78)
    arrow("WAN · NAT 19132", "lan", 1265 - 105, 206, 210, LAN_Y - 206 - 8)
    arrow("web · mail", "lan", 2010 - AW / 2, 206, AW, 78)
    # Cloudflare -> LAN (tunnel), AWS <-> LAN
    arrow("Tunnel (QUIC)", "cf", cf_cx - AW / 2, cf_bottom + 8, AW, LAN_Y - cf_bottom - 16)
    arrow("Vault · mail relay", "secret", 2010 - 130, aws_bottom + 6, 260, LAN_Y - aws_bottom - 12, double=True)
    # Router box -> k8s zone
    arrow("DNS → .101 · L2 VIP", "lan", 1390 - 115, 996, 230, 66)

else:
    cf, tunnel, cfd, traefik, apache = cf_ids[1], cf_ids[3], plat[0], plat[1], ec2[3]
    y_exit = 80 + 0.3 * 114
    edge(internet, cf, "HTTPS via WARP", "cf", True, [(center_x(cf), y_exit)], (0, 0.3), (0.5, 0))
    edge(internet, apache, "web · mail", "lan", True, [(center_x(apache), y_exit)], (1, 0.3), (0.5, 0))
    edge(internet, router, "WAN · NAT 19132", "lan", True, [], (0.5, 1), (0.5, 0))
    edge(cf, tunnel, "proxied CNAME", "cf", True, [], (0.5, 1), (0.5, 0))
    _, ty, _, _ = ABS[tunnel]
    _, cy, _, _ = ABS[cfd]
    edge(tunnel, cfd, "tunnel", "cf", True, [(85, ty + 36), (85, cy + 36)], (0, 0.35), (0, 0.35))
    edge(cfd, traefik, "noTLSVerify", "cf", True, [], (1, 0.35), (0, 0.35))
    edge(router, vips, "*.<domain> → .101", "lan", True, [], (0.5, 1), (0.5, 0))
    edge(vips, traefik, "L2 VIP", "lan", True, [(center_x(vips), 1297), (center_x(traefik), 1297)], (0.5, 1), (0.5, 0))

# GitOps sync: GitHub (below) -> ArgoCD in the cluster (above); shown in both modes.
# ArgoCD pulls from the repo, so the arrow points up into the LAN.
arrow("GitOps sync (ArgoCD pulls)", "git", 560, LAN_Y + LAN_H + 8, 230, 94, direction="north")

# ---- thin local flows (inside zones)
edge(obs[1], obs[4], "", "secret", False, [], (0.5, 1), (0.5, 0))
edge(data[2], data[3], "", "backup", False, [], (1, 0.35), (0, 0.35))
edge(data[3], data[4], "", "backup", False, [], (1, 0.35), (0, 0.35))

# One big frame around everything (inserted first so it sits behind all other cells)
FX, FY, FW = 16, 4, 2584
cells.insert(0, f'<mxCell id="frame" value="" style="rounded=1;arcSize=1;html=1;fillColor={FRAME};strokeColor={ZONES["tool"]};strokeWidth=3;" vertex="1" parent="1">'
    f'<mxGeometry x="{FX}" y="{FY}" width="{FW}" height="{BY + 250 + 24 - FY}" as="geometry"/></mxCell>')

xml = (
    '<mxfile host="app.diagrams.net"><diagram name="Homelab infrastructure map" id="homelab">'
    f'<mxGraphModel dx="1600" dy="1000" grid="0" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" '
    f'page="0" pageScale="1" pageWidth="2600" pageHeight="2400" background="{BG}" math="0" shadow="0">'
    '<root><mxCell id="0"/><mxCell id="1" parent="0"/>' + "".join(cells) + "</root></mxGraphModel></diagram></mxfile>"
)
OUT.write_text(xml)
print(f"wrote {OUT} ({OUT.stat().st_size // 1024} KiB, {len(cells)} cells)")
