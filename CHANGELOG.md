# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

<!-- insertion marker -->
## Unreleased

<small>[Compare with latest](https://github.com/kecsi-san/homelab/compare/v0.1.0...HEAD)</small>

### Fixed

- fix(forgejo-runner): use Recreate strategy for RWO PVC ([9097d59](https://github.com/kecsi-san/homelab/commit/9097d598ffb817520dc806bc351a4cd9dfb282e6) by Zoltan K).
- fix(backstage): move OIDC provider config into custom image app-config ([59fb2fa](https://github.com/kecsi-san/homelab/commit/59fb2fa6f835f9d0df210565848902d92892e856) by Zoltan K).
- fix(ci): use host network + TCP Docker host for job containers ([f957652](https://github.com/kecsi-san/homelab/commit/f957652165b7d35e4d3b97915b72171519230470) by Zoltan K).
- fix(backstage): use schema-based plugin division to avoid createdb permission ([3f0f78b](https://github.com/kecsi-san/homelab/commit/3f0f78bcfbf04fba5b00b11f8547897bb6919e8d) by Zoltan K).
- fix(dns): use ::1 for k3s AAAA wildcard, fd42::1 for k8s only ([0ce04ee](https://github.com/kecsi-san/homelab/commit/0ce04ee57d9e4f4ae315ba016d8df996fc6818dd) by Zoltan K).
- fix(dns): use RouterOS type field to distinguish A/AAAA records; migrate ::1 to fd42::1 ([3991226](https://github.com/kecsi-san/homelab/commit/3991226710a342bb91dc3623ee94023b8b60b663) by Zoltan K).
- fix(dns): add wildcard AAAA overrides to block Cloudflare IPv6 on LAN ([e4a992f](https://github.com/kecsi-san/homelab/commit/e4a992f763c8b31f199220e2edd4bf105e4aa075) by Zoltan K).
- fix(forgejo): increase memory limit 512Mi → 1Gi to prevent OOMKill ([b1a2583](https://github.com/kecsi-san/homelab/commit/b1a25836ee3184d66086ab40b8310438bc349781) by Zoltan K).
- fix(forgejo-runner): chmod /data before register to fix PVC permissions ([1eb8cf8](https://github.com/kecsi-san/homelab/commit/1eb8cf8d4bd4a64e921d4eab75c89a1829fc291a) by Zoltan K).
- fix(forgejo-runner): set workingDir /data on init container ([cd64ac3](https://github.com/kecsi-san/homelab/commit/cd64ac3b50d8d707c29227a10b71d8049ad9dc84) by Zoltan K).
- fix(forgejo-runner): cd /data before register to write .runner to PVC ([f27f1f0](https://github.com/kecsi-san/homelab/commit/f27f1f000cc5eb1e9ab91c7bb13656108900b379) by Zoltan K).
- fix(forgejo-runner): persist runner data on Longhorn PVC ([e2979cf](https://github.com/kecsi-san/homelab/commit/e2979cfe5fa181b790cc4ab45e9507b73676ec53) by Zoltan K).
- fix(forgejo-runner): use wget to wait for DinD instead of docker CLI ([c17aaa0](https://github.com/kecsi-san/homelab/commit/c17aaa0e5de76583f0eb0293647bbb2b029aeb07) by Zoltan K).
- fix(forgejo-runner): use tcp://localhost:2375 for DinD socket ([208bca6](https://github.com/kecsi-san/homelab/commit/208bca607e54498e3f89f8489890702cfebef042) by Zoltan K).
- fix(forgejo-runner): use github.com repo URL in ArgoCD app ([786cebc](https://github.com/kecsi-san/homelab/commit/786cebc70b8dadeb03c6c98a2a0938de6bbb308e) by Zoltan K).
- fix(k8s/authentik): use per_provider issuer_mode for Headlamp OIDC ([4c2cc27](https://github.com/kecsi-san/homelab/commit/4c2cc2764d68397bd0425ffe17d04123aa67aea4) by Zoltan K).
- fix(k8s/traefik): disable kubernetesIngress provider ([18e6ee0](https://github.com/kecsi-san/homelab/commit/18e6ee0b2a21dc40c46910ade3417ed582692480) by Zoltan K).
- fix(k8s/traefik): enable allowCrossNamespace for cross-ns middleware refs ([b1f2f01](https://github.com/kecsi-san/homelab/commit/b1f2f01f2ab86f612f3a382e8260f71d4f0e47bc) by Zoltan K).
- fix(forgejo): use Recreate rollout strategy to avoid LevelDB queue lock ([a5e1902](https://github.com/kecsi-san/homelab/commit/a5e19025366657b04c6e206708ccc54822a5719e) by Zoltan K).
- fix(forgejo): disable remember-me to prevent silent re-login after sign-out ([1d3c960](https://github.com/kecsi-san/homelab/commit/1d3c96068dd92a9e2cf97f5c2c31afdf0c7eae93) by Zoltan K).
- fix(authentik/forgejo): add invalidation_flow to blueprint, fix job app.ini path ([cf86e85](https://github.com/kecsi-san/homelab/commit/cf86e85d63995a8a154183820c5baf5e98325e9a) by Zoltan K).
- fix(configure_ntp): switch from ntpd to chrony (Debian 13 removed ntp package) ([a3a53c3](https://github.com/kecsi-san/homelab/commit/a3a53c3abe1de34c80c4d885d7a87cc8cc818b7f) by Zoltan K).
- fix(k8s/authentik): replace bundled Redis with standalone official image ([20c68d9](https://github.com/kecsi-san/homelab/commit/20c68d92672757ea64d0cc758d332098ae374365) by Zoltan K).
- fix(k8s/authentik): override Redis image registry to registry.bitnami.com ([4fb3cd6](https://github.com/kecsi-san/homelab/commit/4fb3cd6e83356cdd15618a22b416905c1391d942) by Zoltan K).
- fix(k3s/homepage): add Forgejo to Platform section, fix ArgoCD icon ([6fd0abe](https://github.com/kecsi-san/homelab/commit/6fd0abea32e33db2ebde35b3de26c2bdf799aad9) by Zoltan K).
- fix(forgejo): update admin SealedSecret username from admin to kecsi ([bf773f9](https://github.com/kecsi-san/homelab/commit/bf773f9e91f0eda009a1493cd2ca44d4d647142c) by Zoltan K).
- fix(forgejo): use GITEA__ env vars for config, mount PVC at /var/lib/gitea ([800ffed](https://github.com/kecsi-san/homelab/commit/800ffed289c6014824414137b25fca9367137625) by Zoltan K).
- fix(forgejo): split image registry from repository to prevent Gitea chart prepending default registry ([7c0ac01](https://github.com/kecsi-san/homelab/commit/7c0ac014b61061b0505763248b452e647ce823ca) by Zoltan K).
- fix(cnpg): reduce postgres PVC size from 10Gi to 2Gi ([036389b](https://github.com/kecsi-san/homelab/commit/036389b265154607508b1139af1fe641c1c59b1a) by Zoltan K).
- fix(cnpg): add username key to forgejo-db-credentials SealedSecret in postgres ns ([0118228](https://github.com/kecsi-san/homelab/commit/0118228ea8c00a2b278164b5e9e34f4ee9e3d770) by Zoltan K).
- fix(cnpg): add RespectIgnoreDifferences to fix terminatingReplicas schema error ([e87009d](https://github.com/kecsi-san/homelab/commit/e87009d7838ac78377ff51978ad973698470c136) by Zoltan K).
- fix(cnpg): add ServerSideApply to resolve oversized CRD annotation ([2123f77](https://github.com/kecsi-san/homelab/commit/2123f77b70069c0dc2a2909b054ebec8db536724) by Zoltan K).
- fix(homepage): remove background blur to improve image visibility ([7a76f81](https://github.com/kecsi-san/homelab/commit/7a76f81e6b65ff1b8110dc7f9d4c03eb9e0fe7e7) by Zoltan K).
- fix(homepage): correct Glance logo URL (docs/logo.png not docs/images/logo.png) ([f2de1bf](https://github.com/kecsi-san/homelab/commit/f2de1bff89e21fcf7b4cd62f2b4f6c47ecd66b6d) by Zoltan K).
- fix(secrets): add yamllint disable-line comments to SealedSecret encrypted data ([2f506cf](https://github.com/kecsi-san/homelab/commit/2f506cfd8f96e135a6b28142e3c32a11e2eac986) by Zoltan K).
- fix(volsync): add RespectIgnoreDifferences to fix terminatingReplicas schema error ([7fc28e1](https://github.com/kecsi-san/homelab/commit/7fc28e1d826eabe10c09602263d3aa7b079bcaf4) by Zoltan K).
- fix(gatus): correct env format to dict and set Recreate strategy ([537cbe8](https://github.com/kecsi-san/homelab/commit/537cbe80974917a0a260c9bde8f7c6f0dbfe9219) by Zoltan K).
- fix(kube-gitops): restore real domain in operational manifests ([156bc68](https://github.com/kecsi-san/homelab/commit/156bc68257b91f6bfc1c1b0abe77056aa5f3e301) by Zoltan K).

<!-- insertion marker -->
## [v0.1.0](https://github.com/kecsi-san/homelab/releases/tag/v0.1.0) - 2026-05-10

<small>[Compare with first commit](https://github.com/kecsi-san/homelab/compare/c22df6e9f9d59fa012e41442e65b424006cff498...v0.1.0)</small>

### Fixed

- fix(docs): push Headlamp label below icon with leading newlines ([c78ae98](https://github.com/kecsi-san/homelab/commit/c78ae982df4296d79a9be4f95a79878f56ce5468) by Zoltan K).
- fix(docs): resize headlamp icon to 85% (350x435) by resizing the PNG ([90d78dc](https://github.com/kecsi-san/homelab/commit/90d78dc5f84ea6714053a6819066d496117eebb7) by Zoltan K).
- fix(docs): scale Headlamp icon to 85% ([6f239e1](https://github.com/kecsi-san/homelab/commit/6f239e1030a37915edfa1aadf199a75855b5be08) by Zoltan K).
- fix(docs): move GitHub node to right side of diagram ([ce70394](https://github.com/kecsi-san/homelab/commit/ce70394258363f5f1680f8af32650bb19c46738c) by Zoltan K).
- fix(docs): fix custom icon path + force Nodes cluster above sub-clusters ([bbc8ef7](https://github.com/kecsi-san/homelab/commit/bbc8ef786e8764ce08191c393d653a29efeac2d3) by Zoltan K).
- fix(longhorn): add dataLocality best-effort + WaitForFirstConsumer ([0f37e81](https://github.com/kecsi-san/homelab/commit/0f37e81380a4c2ce3dfb33103e8f0a80112eed17) by Zoltan K).
- fix(mikrotik-dns): replace k8s subdomain wildcard with domain-level wildcard ([89240bf](https://github.com/kecsi-san/homelab/commit/89240bf19f672a368154bc541708f80b1a955610) by Zoltan K).
- fix(lint): capitalize handler names to satisfy name[casing] rule ([1293de2](https://github.com/kecsi-san/homelab/commit/1293de2ee47346eb7d3fb00f1f810cfd480328ca) by Zoltan K).
- fix(tls): replace wildcard cert with per-service certs, remove idleTimeout ([4ea0c6f](https://github.com/kecsi-san/homelab/commit/4ea0c6f0f09ffd99db2b6701785376d0c6d4fe63) by Zoltan K).
- fix(k3s): rename kubeconfig context to admin@k3s automatically ([bc34fa1](https://github.com/kecsi-san/homelab/commit/bc34fa17f1a907c77918bc7eef5c86ea170565ed) by Zoltan K).
- fix(post-k8s): rename kubeconfig context to admin@k8s automatically ([c741b7f](https://github.com/kecsi-san/homelab/commit/c741b7f4b50251abfef2bed843d8325582fe4adb) by Zoltan K).
- fix(volsync): switch copyMethod from Snapshot to Clone ([c0fda78](https://github.com/kecsi-san/homelab/commit/c0fda78b4661e47d1104ab6c665b5067eadecb1f) by Zoltan K).
- fix(volsync): regenerate restic sealed secrets cleanly (no manual copy-paste) ([0d2563a](https://github.com/kecsi-san/homelab/commit/0d2563aed89b489d1112bac3dc036691f33c51c1) by Zoltan K).
- fix(volsync): reseal restic secrets against k8s cluster (not k3s) ([098423c](https://github.com/kecsi-san/homelab/commit/098423cde574410761e846ca33b4f6ae55970254) by Zoltan K).
- fix(python-uv): add librouteros to ansible-core extras; use --force on install ([ac869e4](https://github.com/kecsi-san/homelab/commit/ac869e4ccc5f23fdad893829b8743c1d9290b19a) by Zoltan K).
- fix(dns): rename backup.kinet.local → backups.kinet.local ([689f37e](https://github.com/kecsi-san/homelab/commit/689f37e984ff9d0bec589f59126ba611b1c4d0e2) by Zoltan K).
- fix(traefik): disable HTTP/2 to prevent Firefox H2 connection coalescing ([dd62c98](https://github.com/kecsi-san/homelab/commit/dd62c982d59a3100ac16d04e10259eefc2f58537) by Zoltan K).
- fix(volsync): remove ServerSideApply to use lenient diff path ([6368b66](https://github.com/kecsi-san/homelab/commit/6368b665f95c4a2a9bc6c8a6dc99f82d12ee1943) by Zoltan K).
- fix(volsync): ignore terminatingReplicas field missing from ArgoCD schema ([8a1c5fe](https://github.com/kecsi-san/homelab/commit/8a1c5fecdedbde84790ccac80971f782a84aa1d9) by Zoltan K).
- fix(gatus): use strategy.type Recreate for RWO PVC compatibility ([54dde1f](https://github.com/kecsi-san/homelab/commit/54dde1f90d5ffc4c59669f973771b339e5c61414) by Zoltan K).
- fix(garage): add explicit command entrypoint for garage binary ([3c86caa](https://github.com/kecsi-san/homelab/commit/3c86caa598c60c60f1674fdda6a83c7150e6dd9a) by Zoltan K).
- fix: correct garage config path, volsync CRD schema, gatus recreate strategy ([1702195](https://github.com/kecsi-san/homelab/commit/170219595bf0ec58c73bb16c1328fff36315106b) by Zoltan K).
- fix(traefik): set 20s idle connection timeout to prevent stale H2 connections ([fba1e13](https://github.com/kecsi-san/homelab/commit/fba1e13579860e3241104ceaadbd60baabbf340a) by Zoltan K).
- fix(argocd): patch insecure mode in post-k8s.yml after Kubespray install ([7257c13](https://github.com/kecsi-san/homelab/commit/7257c13132b645e57551162d3f0bf817e21deb88) by Zoltan K).
- fix(longhorn): disable pre-upgrade hook for ArgoCD fresh install ([75f0834](https://github.com/kecsi-san/homelab/commit/75f083462a46cae42941c1eb9890a42a357640bd) by Zoltan K).
- fix(k8s): fix Cilium CNI for reliable automated cluster rebuild ([2be1065](https://github.com/kecsi-san/homelab/commit/2be1065552608c544e39b20337d34d2d32893b7a) by Zoltan K).
- fix(router): fix mikrotik-dns playbook and role for first-run reliability ([533f0fd](https://github.com/kecsi-san/homelab/commit/533f0fd5dcd1c4779ef4fe3d8e9bf3df25ec9114) by Zoltan K).
- fix(k8s): use cluster.local as internal DNS domain ([60b718b](https://github.com/kecsi-san/homelab/commit/60b718b6d0ddc8f96323dbff79b72e2180073788) by Zoltan K).
- fix(security): remove hardcoded email from ClusterIssuer manifests ([ddbd836](https://github.com/kecsi-san/homelab/commit/ddbd836ba0eed0d04c0a42ff68c435b5adc58d87) by Zoltan K).
- fix(uv): add netaddr to ansible-core tool extras (required by Kubespray) ([43613f3](https://github.com/kecsi-san/homelab/commit/43613f39162d4279ab387fcd8c6e9febfc35eb62) by Zoltan K).
- fix(uv): add ~/.local/bin to PATH via blockinfile instead of update-shell ([3af0dde](https://github.com/kecsi-san/homelab/commit/3af0ddee4e8f8daee1a76445ff1344e0a59492b7) by Zoltan K).
- fix(uv): run uv tool update-shell to add ~/.local/bin to PATH ([ce31dd5](https://github.com/kecsi-san/homelab/commit/ce31dd5baba7529640a79ebf7d3cae627c7f7802) by Zoltan K).
- fix(uv): install ansible-core instead of ansible meta-package ([0cdd3cc](https://github.com/kecsi-san/homelab/commit/0cdd3cc4d51bef6cbe86fa0cac79faa5ef83488c) by Zoltan K).
- fix(uv): pin ansible to >=11,<12 for Kubespray 2.31 compatibility ([78203ee](https://github.com/kecsi-san/homelab/commit/78203eea705efc91596f8bedec84c17f72385fe0) by Zoltan K).
- fix(k3s): run Traefik as root for privileged port binding on WSL2 ([1163d10](https://github.com/kecsi-san/homelab/commit/1163d109190966455a0a112dea4750ff15e8af6e) by Zoltan K).
- fix(k3s): use Recreate strategy for Traefik with hostNetwork ([025ac7a](https://github.com/kecsi-san/homelab/commit/025ac7ad29541e86503817c929fbcbece6691617) by Zoltan K).
- fix(k3s): bind Traefik to ports 80/443 with NET_BIND_SERVICE for hostNetwork ([63d6c12](https://github.com/kecsi-san/homelab/commit/63d6c12bac6713f8ebc56cc795941196cd7cb076) by Zoltan K).
- fix(k3s): change Traefik metrics port to 9101 (9100 taken by node-exporter) ([4c15b51](https://github.com/kecsi-san/homelab/commit/4c15b519812d0e350cc64e292572df7f8e99a228) by Zoltan K).
- fix(k3s): correct hostNetwork to top-level key in Traefik values ([62d0238](https://github.com/kecsi-san/homelab/commit/62d023880c8e92880a7e414073818c59c4864912) by Zoltan K).
- fix(k3s): use hostNetwork+ClusterIP for Traefik on WSL2 mirrored mode ([0a60570](https://github.com/kecsi-san/homelab/commit/0a60570a4dc7a6e357ac0d75c63ac96d36f5864d) by Zoltan K).
- fix(k3s): add hostPort to Traefik for WSL2 mirrored mode ([1d28d72](https://github.com/kecsi-san/homelab/commit/1d28d7240941064026bf7cb04cbfeb9e9e29b315) by Zoltan K).
- fix(ci): pass RENOVATE_REPOSITORIES so self-hosted Renovate finds the repo ([dc43e9c](https://github.com/kecsi-san/homelab/commit/dc43e9c565cdf6ddbfbda86efb33677b2e2a34c2) by Zoltan K).
- fix(ci): pin renovatebot/github-action to v46.1.13 (no major tags published) ([b99a4e1](https://github.com/kecsi-san/homelab/commit/b99a4e1ccb81aa6545982cbf75857d8a36c70e57) by Zoltan K).
- fix(ci): correct renovatebot/github-action version to v46 ([aeb393f](https://github.com/kecsi-san/homelab/commit/aeb393f9a6291ba04bad34742a897d6222d0f305) by Zoltan K).
- fix: correct Traefik dashboard URL in Homepage to include /dashboard/ path ([0d4c135](https://github.com/kecsi-san/homelab/commit/0d4c13528a0b2e9abc151cc839581d1d97031bf8) by Zoltan K).
- fix: set HOMEPAGE_ALLOWED_HOSTS env var for host validation ([5cd8532](https://github.com/kecsi-san/homelab/commit/5cd8532f5f970ccae93cff22427d353518743929) by Zoltan K).
- fix: allow homepage.kecskemethy.org in Homepage host validation ([4c349a9](https://github.com/kecsi-san/homelab/commit/4c349a91dfcf1d6b5a141e65f499ca304e8a029d) by Zoltan K).
- fix: disable HTTP/3 on k8s Traefik — kube-vip LB is TCP-only, QUIC/UDP fails ([d78d954](https://github.com/kecsi-san/homelab/commit/d78d954e0ad0f88e6843e17b5f56cf96290dfa6a) by Zoltan K).
- fix: cloudflared metrics on 0.0.0.0 so liveness probe can reach it ([632050e](https://github.com/kecsi-san/homelab/commit/632050eb3ddb6682cfb7a827bb25258c91fbffaf) by Zoltan K).
- fix: update Traefik redirect syntax for chart v34 ([d583069](https://github.com/kecsi-san/homelab/commit/d5830695bca94e92bcb3ee97fdeae273cb47528d) by Zoltan K).
- fix: remove apex domain from wildcard cert — wildcard is sufficient ([13a9ebf](https://github.com/kecsi-san/homelab/commit/13a9ebf49817521d9c3f6bb9b961765e589c3305) by Zoltan K).
- fix: skip ansible-lint when vault password is unavailable (Dependabot) ([6171d8a](https://github.com/kecsi-san/homelab/commit/6171d8a09aae80ca9c971534a89f24f60bab77b3) by Zoltan K).
- fix: break long line in configure_oh-my-posh theme selection ([43edd7b](https://github.com/kecsi-san/homelab/commit/43edd7b700f2e496a143ca1d5b90c47d15c3302e) by Zoltan K).
- fix: resolve ansible-lint key-order and name-casing violations ([a4925fe](https://github.com/kecsi-san/homelab/commit/a4925fea70c9c860d1bd7fcab5cfcadb7fb26357) by Zoltan K).
- fix: resolve macOS interpreter and uv upgrade path issues ([d73ba8d](https://github.com/kecsi-san/homelab/commit/d73ba8de1866b0260bfed949d2365ad72a365911) by Zoltan K).
- fix: skip pip install task when uv_pip_packages is empty ([fd1632d](https://github.com/kecsi-san/homelab/commit/fd1632d61f1d270c66cabb541428f9e8f04d48ff) by Zoltan K).
- fix: handler for sshd reload and serial upgrade ([18c6a2b](https://github.com/kecsi-san/homelab/commit/18c6a2b4ded7c1c093bcd6858a212a4608b1aa5e) by Zoltan K).
- fix: make kubeseal completion non-fatal when controller is unreachable ([4282a6f](https://github.com/kecsi-san/homelab/commit/4282a6fcbf691437ba087400e0bdebeb67d9345b) by Zoltan K).
- fix: replace helm_plugin module with command for helm-diff install ([d2ef92b](https://github.com/kecsi-san/homelab/commit/d2ef92b1865c3f105930b0b4905f4d6be148e775) by Zoltan K).
- fix: resolve helm-diff missing and Python interpreter warnings ([7e73bdd](https://github.com/kecsi-san/homelab/commit/7e73bddad43ac9174aa4a3bedf1cfc87a838a0d0) by Zoltan K).
- fix: update ansible-lint exclusions for renamed kubespray playbooks ([68387fb](https://github.com/kecsi-san/homelab/commit/68387fb311e49f4586fa2e9ca402ac45adfcf939) by Zoltan K).
- fix: remove committed profile image and make it user-provided ([2ac9145](https://github.com/kecsi-san/homelab/commit/2ac9145d5405acdd5f9a2095c2f293af1a3ec659) by Zoltan K).
- fix: make roles cross-platform (Linux + macOS) ([8538b75](https://github.com/kecsi-san/homelab/commit/8538b754cf3989ca30ee13910abaf8e07b50fd7c) by Zoltan K).
- fix: add vault password file creation in CI ([886d91c](https://github.com/kecsi-san/homelab/commit/886d91cc3801da8abc4428fee0575d5f645034c6) by Zoltan K).
- fix: exclude .venv from yamllint and fix collections_path for CI ([be52435](https://github.com/kecsi-san/homelab/commit/be52435f67b91e53f15b8299cfe3d41347d86a32) by Zoltan K).
- fix: resolve all ansible-lint and yamllint violations ([ff13f13](https://github.com/kecsi-san/homelab/commit/ff13f134291d4e36c874080413bd24d64b1c654d) by Zoltan K).
- fix: restore DOCUMENTATION block in profile_tasks callback override ([a466d22](https://github.com/kecsi-san/homelab/commit/a466d225c42a9695ffbb7abe11495039266f6a6a) by Zoltan K).
- fix: use K3S_KUBECONFIG_MODE=644 to avoid become for kubeconfig copy ([ea0fdac](https://github.com/kecsi-san/homelab/commit/ea0fdacd961d4d1ab3ad14eacb41b4adbbaefa00) by Zoltan K).
- fix: restore remote_src: true on k3s kubeconfig copy task ([3e33526](https://github.com/kecsi-san/homelab/commit/3e33526956d1635ea51b9c41c7d7a8f439cfd0ba) by Zoltan K).
- fix: remote_src param remove from setup_k3s role ([ac3ac62](https://github.com/kecsi-san/homelab/commit/ac3ac6204fc3b794937e27245f59dd48e6ae6bc2) by Zoltan K).
- fix: replace embedded Jinja templates in lookup with ~ concatenation ([fdc32ee](https://github.com/kecsi-san/homelab/commit/fdc32ee0ade15d3707f6e6d7f0a7356e1b344ec8) by Zoltan K).
- fix: remove duplicate python_version var second occasion from setup_python-uv role ([3197a5c](https://github.com/kecsi-san/homelab/commit/3197a5c673f7e584ac0cb2bbe8b3baa1813f3344) by Zoltan K).
- fix: hard code uv python venv version to 3.12 ([5fa6490](https://github.com/kecsi-san/homelab/commit/5fa64908ada66b69416449749538bba302f4b6b0) by Zoltan K).
- fix: remove aspose-diagram packages — require jpype1 which needs g++-12 ([ab22c95](https://github.com/kecsi-san/homelab/commit/ab22c95f03deba690b41dcc1c1e822cd4d27b9b4) by Zoltan K).
- fix: remove dot2mmd — not found in PyPI registry ([379ccf8](https://github.com/kecsi-san/homelab/commit/379ccf88d8cca970488bdf3bd16da2f9d6c497d0) by Zoltan K).
- fix: move all inline comments to their own lines in .gitignore ([cecd5b8](https://github.com/kecsi-san/homelab/commit/cecd5b8bcfb5189468eabd980c80da110f702f39) by Zoltan K).
- fix: remove diagraform — not found in PyPI registry ([01b4858](https://github.com/kecsi-san/homelab/commit/01b485837f61c402ed6c51b6941c1d23fb75c542) by Zoltan K).
- fix: use lookup('env', 'HOME') for uv venv path ([594253a](https://github.com/kecsi-san/homelab/commit/594253aba38f1c7d2341903b6626b2f670cdc6cf) by Zoltan K).
- fix: install mkdocs (not mkdocs-material) as uv tool ([60801d9](https://github.com/kecsi-san/homelab/commit/60801d9bee5c5fdd3dd00e9f309e9758b3401342) by Zoltan K).
- fix: switch playbooks from roles: to import_role for correct tag filtering ([4076d92](https://github.com/kecsi-san/homelab/commit/4076d922f9927af7f4e9a27180fba9a9056878c5) by Zoltan K).

