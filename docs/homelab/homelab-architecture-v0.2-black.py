"""
Homelab infrastructure map, generated with the Python diagrams library (dark mode).

Run:  source ~/.venv/devops/bin/activate && python3 docs/homelab/homelab-architecture-v0.2-black.py
Out:  docs/homelab/homelab-architecture-v0.2-black.png

Conventions
- Cluster (box) colour = network zone, see ZONES / the legend in the diagram.
- A service gets a logo node (icons/<name>.png) when a logo exists; services
  without one are collected in a bullet-list box instead.
- Dashed boxes/edges = planned, not deployed yet.
- Hostnames and private IPs only; no secrets or personal identifiers.
"""

from contextlib import contextmanager
from pathlib import Path

from diagrams import Cluster, Diagram, Edge, Node
from diagrams.custom import Custom

ICONS = Path(__file__).parent / "icons"
OUT = Path(__file__).parent / "homelab-architecture-v0.2-black"

# --- Palette (GitHub-dark inspired) ---------------------------------------
BG = "#0d1117"
CARD = "#161b22"
TEXT = "#e6edf3"
MUTED = "#8b949e"

ZONES = {
    "lan": "#388bfd",  # 192.168.1.0/24 (flat, no VLANs yet)
    "pod": "#39c5cf",  # Kubernetes pod/service network (Cilium)
    "aws": "#d29922",  # AWS VPC (edge node)
    "cf": "#f0883e",  # Cloudflare edge
    "dev": "#3fb950",  # WSL2 workstation + k3s dev cluster
    "tool": "#768390",  # control node / tooling
    "plan": "#db61a2",  # planned
}

# Flow colours are deliberately disjoint from ZONES so a line never reads as a zone.
FLOW = {
    "lan": "#ffffff",  # ingress / LAN path
    "cf": "#ff5c5c",  # Cloudflare Tunnel path
    "secret": "#ffe14d",  # TLS / DNS automation / alerts
    "backup": "#c8a27a",  # backups
}


_stack = []


class Zone:
    """Direct child nodes of a cluster, wrapped into `cols` columns on exit."""

    def __init__(self, cols):
        self.cols = cols
        self.nodes = []

    @property
    def first(self):
        return self.nodes[0]

    @property
    def last_row(self):
        n = len(self.nodes)
        start = ((n - 1) // self.cols) * self.cols
        return self.nodes[start:]


def link(a, b, minlen=1):
    """Invisible edge: only used to steer graphviz's rank/column layout."""
    a >> Edge(style="invis", minlen=str(minlen)) >> b


def register(node):
    if _stack:
        _stack[-1].nodes.append(node)
    return node


@contextmanager
def zone(label, key, dashed=False, fill="20", cols=3):
    """Coloured cluster box; `fill` is the alpha hex of the background tint."""
    z = Zone(cols)
    _stack.append(z)
    color = ZONES[key]
    attrs = {
        "bgcolor": f"{color}{fill}",
        "pencolor": color,
        "fontcolor": color,
        "fontname": "Sans-Serif Bold",
        "fontsize": "15",
        "penwidth": "2",
        "style": "rounded,dashed" if dashed else "rounded",
        "margin": "18",
        "labeljust": "l",
    }
    with Cluster(label, graph_attr=attrs):
        yield z
    _stack.pop()
    for i in range(0, len(z.nodes) - cols):
        link(z.nodes[i], z.nodes[i + cols])


def logo(label, name, **kw):
    """Service with a logo (icons/<name>.png)."""
    return register(Custom(label, str(ICONS / f"{name}.png"), fontcolor=TEXT, fontsize="11", **kw))


def listbox(title, lines, key="tool", dashed=False, **kw):
    """Services without a logo: a bullet list in a card."""
    body = f"{title}\\l" + "".join(f"  • {line}\\l" for line in lines)
    return register(Node(
        body,
        shape="box",
        style="rounded,filled" + (",dashed" if dashed else ""),
        fillcolor=CARD,
        color=ZONES[key],
        fontcolor=TEXT,
        fontsize="11",
        fixedsize="false",
        width="0",
        height="0",
        margin="0.18,0.12",
        labelloc="c",
        **kw,
    ))


def flow(src, dst, label, key, constrain=False):
    """Main traffic flow: a thick arrow, distinct from the thin local flows.

    Double-line styles (parallel colours, or a thin edge overlaid on a thick one) don't
    work with ortho routing in graphviz: the two edges get routed differently.
    """
    src >> Edge(
        xlabel=label,
        color=FLOW[key],
        fontcolor=FLOW[key],
        fontsize="10",
        penwidth="5",
        arrowsize="1.1",
        constraint="true" if constrain else "false",
    ) >> dst


def legendbox(title, rows):
    """Legend card: coloured swatch + text per row (HTML-like label)."""
    body = "".join(
        f'<TR><TD ALIGN="LEFT"><FONT COLOR="{color}">&#9632;</FONT>  {text}</TD></TR>'
        for color, text in rows
    )
    label = (
        '<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="3">'
        f'<TR><TD ALIGN="LEFT"><B>{title}</B></TD></TR>{body}</TABLE>>'
    )
    return register(
        Node(
            label,
            shape="box",
            style="rounded,filled",
            fillcolor=CARD,
            color=ZONES["tool"],
            fontcolor=TEXT,
            fontsize="11",
            fixedsize="false",
            width="0",
            height="0",
            margin="0.18,0.12",
        )
    )


def edge(label="", flow="lan", dashed=False, traffic=False, constrain=False):
    """traffic=True draws a double line (two parallel strokes) for main network flows."""
    color = f"{FLOW[flow]}:{FLOW[flow]}" if traffic else FLOW[flow]
    return Edge(
        xlabel=label,  # ortho routing ignores plain labels
        color=color,
        fontcolor=FLOW[flow],
        fontsize="10",
        style="dashed" if dashed else "solid",
        penwidth="2.2" if traffic else "1.6",
        arrowsize="1.3" if traffic else "1",
        constraint="true" if constrain else "false",
    )


graph_attr = {
    "bgcolor": BG,
    "fontcolor": TEXT,
    "fontsize": "30",
    "fontname": "Sans-Serif Bold",
    "labelloc": "t",
    "labeljust": "l",
    "pad": "0.6",
    "splines": "ortho",
    "nodesep": "0.45",
    "ranksep": "0.9",
    "compound": "true",
    "forcelabels": "true",
}
node_attr = {"fontname": "Sans-Serif", "fontcolor": TEXT, "fontsize": "11"}
edge_attr = {"fontname": "Sans-Serif"}

with Diagram(
    "Homelab · infrastructure map",
    show=False,
    direction="TB",
    filename=str(OUT),
    graph_attr=graph_attr,
    node_attr=node_attr,
    edge_attr=edge_attr,
):
    # ---------------------------------------------------------------- internet
    with zone("Public network", "tool", fill="10", cols=1) as z_net:
        internet = logo("Internet\nusers · mail · Minecraft", "internet")

    # ---------------------------------------------------- internet / cloudflare
    with zone("Internet · Cloudflare edge", "cf", cols=2) as z_cf:
        users = listbox(
            "Clients",
            [
                "Edge browser (LAN path)",
                "Firefox + WARP (Cloudflare path)",
                "Minecraft Bedrock (UDP 19132)",
            ],
            key="cf",
        )
        cf = logo("Cloudflare\nDNS · proxy · ECH", "cloudflare")
        tunnel = logo("Cloudflare Tunnel\noutbound QUIC", "cloudflared")
        le = logo("Let's Encrypt\nDNS-01 certs", "lets-encrypt")

    # ------------------------------------------------------------------- AWS
    with zone("AWS · single production edge node (Debian, Terraform-managed)", "aws", cols=1) as z_aws:
        with zone("EC2 · mail, web, secrets", "aws", fill="18", cols=4) as z_ec2:
            apache = logo("Apache2\n+ ModSecurity", "apache")
            postfix = logo("Postfix\nSMTP", "postfix")
            dovecot = logo("Dovecot\nIMAPS", "dovecot")
            vault = logo("Vault\nsecrets KV", "hashicorp-vault")
            unbound = logo("Unbound\nDNSSEC resolver", "unbound")
            duo = logo("Duo\nSSH MFA (PAM)", "duo")
            logo("Rspamd\nspam · DKIM", "rspamd")
            listbox(
                "Also on the box",
                ["OpenDMARC + Postscreen", "certbot (Route53 DNS-01)", "fail2ban · SSM agent"],
                key="aws",
            )
        with zone("AWS services", "aws", fill="18", cols=2) as z_awssvc:
            logo("AWS\nEC2 · EIP · SG", "aws")
            listbox("Route53 + S3", ["Route53 zones", "S3 remote state"], key="aws")
        wg = logo("WireGuard hub\n(planned)", "wireguard")

    # ------------------------------------------------------------------ router
    with zone("LAN · 192.168.1.0/24 · flat network, no VLANs yet", "lan", fill="12", cols=2) as z_lan:
        router = logo("MikroTik router\n192.168.1.1 · WAN edge", "mikrotik")
        router_info = listbox(
            "Router role",
            [
                "split-horizon DNS: *.<domain> → .101",
                "static records (prolion, backups, api VIP)",
                "dst-nat UDP 19132 → .110",
                "NTP source for all nodes",
            ],
            key="lan",
        )

        # ------------------------------------------------------------- k8s
        with zone("k8s · Kubespray 2.31 · Kubernetes 1.35 · Cilium", "pod", fill="14", cols=1) as z_k8s:
            with zone("Nodes (Debian)", "lan", fill="22", cols=4) as z_nodes:
                n1 = logo("hped800g5 · .18\ncontrol-plane + etcd\ni5-9500T · 32 GB", "kubernetes")
                n2 = logo("hped800g62 · .34\ncontrol-plane + etcd\ni5-10500T · 24 GB", "kubernetes")
                n3 = logo("hppd600g6 · .52\ncontrol-plane + etcd\nNFS + restic REST", "kubernetes")
                n4 = logo("hped800g61 · .36\nworker\ni5-10500T · 16 GB", "kubernetes")
            logo("kube-vip\nL2 VIPs", "kube-vip")
            vips = listbox(
                "kube-vip virtual IPs (L2/ARP)",
                [".100  Kubernetes API (api.k8s.<domain>)", ".101  Traefik LoadBalancer", ".110  Minecraft Bedrock (UDP)"],
                key="lan",
            )

            with zone("Platform", "pod", fill="22", cols=4) as z_plat:
                cilium = logo("Cilium\nCNI · eBPF", "cilium")
                traefik = logo("Traefik\ningress", "traefik")
                certm = logo("cert-manager\nper-service certs", "cert-manager")
                argocd = logo("ArgoCD\napp-of-apps", "argo-cd")
                cfd = logo("cloudflared\n2 replicas", "cloudflared")
                logo("Reloader", "reloader")
                logo("external-dns\nCloudflare sync", "external-dns")
                logo("External Secrets\n→ Vault", "external-secrets")
                platform_list = listbox(
                    "More",
                    ["Sealed Secrets", "pod-cleanup CronJob"],
                    key="pod",
                )

            with zone("Identity & developer tools", "pod", fill="22", cols=3) as z_id:
                logo("Authentik\nSSO / OIDC", "authentik")
                logo("Forgejo\ngit · OCI · CI", "forgejo")
                logo("Backstage\nportal", "backstage")
                logo("Headlamp\nk8s UI", "headlamp")
                logo("Forgejo runner\nActions CI", "forgejo")
                logo("Wiki.js\nwiki", "wiki-js")

            with zone("Observability", "pod", fill="22", cols=3) as z_obs:
                prom = logo("Prometheus", "prometheus")
                logo("Alertmanager", "alertmanager")
                logo("Grafana\noperator", "grafana")
                logo("Gatus\nuptime", "gatus")
                ntfy = logo("ntfy\npush alerts", "ntfy")
                logo("kromgo\nstatus badges", "kromgo")

            with zone("Data & storage", "pod", fill="22", cols=2) as z_data:
                longhorn = logo("Longhorn\nblock storage", "longhorn")
                pg = logo("CloudNativePG\n3× PostgreSQL", "cloudnativepg")
                restic_srv = logo("restic REST\nhppd600g6 :8000", "restic")
                logo("Garage\nS3", "garage")
                volsync = listbox("VolSync", ["PVC backups via restic", "ntfy · gatus · mealie · minecraft"], key="pod")

            with zone("Apps", "pod", fill="22", cols=2) as z_apps:
                logo("Mealie\nrecipes", "mealie")
                logo("Minecraft\nBedrock", "minecraft")
                logo("Glance\ndashboard", "glance")
                logo("Homepage\nstart page", "homepage")
                logo("OpenCloud\nfiles", "opencloud")

        # -------------------------------------------------------- prolion
        with zone("prolion · 192.168.1.10 · Debian 13 file server", "lan", fill="22", cols=3) as z_prolion:
            prolion_j = logo("Jellyfin", "jellyfin")
            logo("Transmission", "transmission")
            prolion_l = listbox("Also", ["thumbsup photo gallery", "Minecraft", "7.3 TB /stuff array", "Postfix → EC2 relay"], key="lan")

    # ------------------------------------------------------- workstation / k3s
    with zone("Workstation · Windows 11 + WSL2 (192.168.1.25)", "dev", cols=2) as z_ws:
        logo("Windows 11\ndesktop", "windows-11")
        with zone("k3s · single-node dev cluster", "dev", fill="22", cols=3) as z_k3s:
            logo("k3s\nlocal-path storage", "k3s")
            logo("Traefik", "traefik")
            logo("Authentik", "authentik")
            listbox("Mostly scaled to 0", ["Forgejo + runner", "Wiki.js", "Homepage · Headlamp"], key="dev")
        ctl = logo("Control node\nAnsible · kubectl", "ansible")

    # ----------------------------------------------------------------- planned
    with zone("Planned", "plan", dashed=True, fill="10", cols=2) as z_plan:
        ipam = logo("IPAM (NetBox)\nIPs · VLANs · hosts", "netbox")
        listbox("Also planned", ["VLAN segmentation", "Cilium LB-IPAM / BGP", "WireGuard spokes"], key="plan", dashed=True)

    # ------------------------------------------------------------- built with
    with zone("Built and managed with", "tool", fill="10", cols=4) as z_built:
        logo("Ansible\nhost config", "ansible")
        logo("Terraform\nAWS · Vault", "terraform")
        logo("Helm\nchart installs", "helm")
        logo("Renovate\nversion bumps", "renovate")
        gh = logo("GitHub\nmonorepo", "github")
        logo("Git", "git")
        logo("Kubespray\ncluster lifecycle", "kubespray")
        listbox("More", ["GitHub monorepo → ArgoCD sync", "kubeseal · just · pre-commit"], key="tool")

    # ---------------------------------------------------------------- legend
    with zone("Legend", "tool", fill="10", cols=2) as z_legend:
        legendbox(
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
        )
        legendbox(
            "Flows (line colour)",
            [
                (FLOW["lan"], "main traffic, direct (thick line)"),
                (FLOW["cf"], "main traffic via Cloudflare (thick line)"),
                (FLOW["secret"], "alerts"),
                (FLOW["backup"], "backups (restic)"),
                (MUTED, "&quot;More&quot; boxes list services without a logo"),
            ],
        )

    # ------------------------------------------------------- layout steering
    # Rows, top to bottom. Each row hangs off the deepest grid row above it.
    rows = [
        [z_net],
        [z_cf, z_ec2, z_awssvc],
        [z_lan],
        [z_nodes, z_prolion],
    ]
    for upper, lower in zip(rows, rows[1:]):
        for u in upper:
            for lo in lower:
                link(u.last_row[0], lo.first)
    link(z_nodes.last_row[0], vips)
    for z in (z_plat, z_id, z_obs):
        link(vips, z.first)
    for z in (z_data, z_apps):
        for up in (z_plat, z_id, z_obs):
            link(up.last_row[0], z.first)
    for z in (z_ws, z_plan, z_built):
        for up in (z_data, z_apps, z_prolion):
            link(up.last_row[0], z.first)

    for up in (z_ws, z_plan, z_built):
        link(up.last_row[0], z_legend.first)

    # ------------------------------------------------------------------ edges
    # Only short, local flows are drawn. Long cross-zone paths (Cloudflare Tunnel ->
    # cloudflared -> Traefik, router DNS -> VIP) are written into the node labels
    # instead, because drawn lines looped around the whole map.
    # Main network traffic (double lines), top to bottom
    flow(internet, cf, "HTTPS via WARP", "cf", constrain=True)
    flow(cf, tunnel, "proxied CNAME", "cf", constrain=True)
    flow(tunnel, cfd, "tunnel", "cf", constrain=False)
    flow(cfd, traefik, "noTLSVerify", "cf", constrain=False)
    flow(internet, router, "WAN · NAT 19132", "lan", constrain=True)
    flow(router, vips, "*.<domain> → .101", "lan", constrain=True)
    flow(vips, traefik, "L2 VIP", "lan", constrain=True)
    flow(internet, apache, "web · mail", "lan", constrain=False)

    # Local single-line flows
    longhorn >> edge("snapshot clone", "backup") >> volsync
    volsync >> edge("restic", "backup") >> restic_srv
    prom >> edge("alerts", "secret") >> ntfy
