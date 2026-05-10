"""
Homelab architecture diagram — generated with the Python diagrams library.
Run: source ~/.venv/devops/bin/activate && python3 docs/homelab-architecture.py
Output: docs/homelab-architecture.png
"""

from pathlib import Path

from diagrams import Diagram, Cluster, Edge
from diagrams.custom import Custom
from diagrams.generic.network import VPN
from diagrams.k8s.infra import Node
from diagrams.onprem.certificates import CertManager, LetsEncrypt
from diagrams.onprem.compute import Server
from diagrams.onprem.gitops import ArgoCD
from diagrams.onprem.network import Traefik
from diagrams.onprem.storage import Ceph
from diagrams.onprem.vcs import Github
from diagrams.saas.cdn import Cloudflare

# Resolve icons relative to this script file — works regardless of working dir
ICONS = Path(__file__).parent / "icons"

graph_attr = {
    "fontsize": "20",
    "bgcolor": "white",
    "pad": "0.5",
    "splines": "ortho",
}

node_attr = {
    "fontsize": "12",
}

with Diagram(
    "Homelab Architecture",
    show=False,
    direction="TB",
    filename="docs/homelab-architecture",
    graph_attr=graph_attr,
    node_attr=node_attr,
):
    github = Github("ansible-env-setup\n(GitOps repo)")
    le = LetsEncrypt("Let's Encrypt\n(DNS01 via CF API)")

    with Cluster("Client — Win11 Desktop"):
        edge_browser = Server("Edge Browser\n(LAN path)")
        warp_client = VPN("Firefox + WARP\n(Cloudflare path)")

    with Cluster("Cloudflare"):
        cf_edge = Cloudflare("Edge\nUniversal SSL")

    with Cluster("LAN — 192.168.1.0/24"):
        router = Server("MikroTik Router\n*.kecskemethy.org\n→ 192.168.1.101")

        with Cluster("k8s Cluster  ·  Kubespray 2.31  ·  k8s 1.35"):

            with Cluster("Nodes"):
                cp1 = Node("hped800g5\n192.168.1.18\ncontrol-plane")
                cp2 = Node("hped800g62\n192.168.1.34\ncontrol-plane")
                cp3 = Node("hppd600g6\n192.168.1.52\ncontrol-plane + NFS")
                w1 = Node("hped800g61\n192.168.1.36\nworker")

            with Cluster("Ingress & Tunnel"):
                kubevip = Server("kube-vip\n.100 (API VIP)\n.101 (Traefik LB)")
                traefik = Traefik("Traefik\nIngress Controller")
                cloudflared = VPN("cloudflared\n(QUIC tunnel)")

            with Cluster("Platform"):
                certmgr = CertManager("cert-manager\n(per-service LE certs)")
                argocd_ctrl = ArgoCD("ArgoCD\n(app-of-apps GitOps)")
                sealed = Server("Sealed Secrets")

            with Cluster("Storage & Backup"):
                longhorn = Ceph("Longhorn\n(distributed block)")
                volsync = Server("VolSync\n(PVC snapshots)")
                restic = Server("Restic REST Server\nhppd600g6:8000")

            with Cluster("Services"):
                homepage = Server("Homepage")
                argocd = ArgoCD("ArgoCD")
                headlamp = Custom("\n\nHeadlamp", str(ICONS / "headlamp.png"))
                gatus = Custom("Gatus\n(uptime monitoring)", str(ICONS / "gatus.png"))
                ntfy = Custom("ntfy\n(push + email alerts)", str(ICONS / "ntfy.png"))
                mealie = Custom("Mealie\n(recipes)", str(ICONS / "mealie.png"))

            with Cluster("LAN-Only Services"):
                longhorn_ui = Server("Longhorn UI")
                traefik_dash = Traefik("Traefik Dashboard")

            # Force Nodes above the other sub-clusters via invisible edges
            cp1 >> Edge(style="invis") >> kubevip
            cp1 >> Edge(style="invis") >> certmgr
            cp1 >> Edge(style="invis") >> longhorn

    # Pull GitHub to the right, near Let's Encrypt
    le >> Edge(style="invis") >> github

    # --- Traffic flows ---
    # LAN path
    edge_browser >> router >> kubevip >> traefik

    # Cloudflare path
    warp_client >> cf_edge >> cloudflared >> traefik

    # Traefik → services
    traefik >> [homepage, argocd, headlamp, gatus, ntfy, mealie]
    traefik >> [longhorn_ui, traefik_dash]

    # GitOps
    github >> Edge(label="sync") >> argocd_ctrl
    argocd_ctrl >> Edge(label="manages") >> traefik

    # TLS
    certmgr >> Edge(label="DNS01 challenge") >> le
    certmgr >> Edge(label="LE certs") >> traefik

    # Storage
    longhorn >> Edge(label="snapshot") >> volsync >> Edge(label="restic backup") >> restic
