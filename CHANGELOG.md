# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

<!-- insertion marker -->
## Unreleased

<small>[Compare with latest](https://github.com/kecsi-san/homelab/compare/v0.2.0...HEAD)</small>

### Fixed

- fix(minecraft): run VolSync backup mover as uid 1000 to match world file ownership ([5a25c24](https://github.com/kecsi-san/homelab/commit/5a25c24300e43b1070ab2d3960d4c0da0c3db402) by Zoltan K).
- fix(minecraft): revert LEVEL_NAME to world, alias via PVC symlink ([3bcee07](https://github.com/kecsi-san/homelab/commit/3bcee073748dfb715c40adccd8e978cb0a37da87) by Zoltan K).

<!-- insertion marker -->
## [v0.2.0](https://github.com/kecsi-san/homelab/releases/tag/v0.2.0) - 2026-07-31

<small>[Compare with v0.1.0](https://github.com/kecsi-san/homelab/compare/v0.1.0...v0.2.0)</small>

### Added

- Add apt-nodesource install method to node roles, onboard prolion ([0360ed0](https://github.com/kecsi-san/homelab/commit/0360ed011a64fb52163d12e33201b4b9a305ceb1) by Zoltan K).

### Fixed

- fix(wsl2): pre-correct clock via [boot] command before systemd starts ([07a689b](https://github.com/kecsi-san/homelab/commit/07a689b672b16abd4502bc5b2dbb4e4e434b9439) by Zoltan K).
- fix(mail,apache): close aliases/SAN gaps found vs legacy server ([735c5bc](https://github.com/kecsi-san/homelab/commit/735c5bc617dec94265c9f74dd5e1647ade322df9) by Zoltan K).
- fix(mail): match legacy server's proven SMTPS/DMARC config exactly ([272ccf9](https://github.com/kecsi-san/homelab/commit/272ccf93896ab77b78cdfe6d36bc17334056c21f) by Zoltan K).
- fix(ec2-rebuild): resolve Phase 6 blockers found in legacy-instance audit ([7f402ad](https://github.com/kecsi-san/homelab/commit/7f402ad511c79f4e6e161d2cb13929f4c6383961) by Zoltan K).
- fix(lint): suppress false-positive jinja[invalid] on DKIM TXT chunking ([a38c7ee](https://github.com/kecsi-san/homelab/commit/a38c7ee5e7e8486be76916e96dda0ec66efc5e92) by Zoltan K).
- fix(ci): drop kubespray from lint's collection install, keep it fast ([aee908e](https://github.com/kecsi-san/homelab/commit/aee908e78356ced0f052aa1c422f32b4925250fa) by Zoltan K).
- fix(ci): install collections from requirements.yml in lint workflow ([ee77939](https://github.com/kecsi-san/homelab/commit/ee77939890898ea061a6730277710eb83a8abe93) by Zoltan K).
- fix(dkim): make Vault the DKIM value source, fix live Route53 corruption ([3d403e7](https://github.com/kecsi-san/homelab/commit/3d403e796b8e79ef1714873b21080ec45f12813b) by Zoltan K).
- Fix oh-my-posh theming for prolion, correct git identity leak ([104e69b](https://github.com/kecsi-san/homelab/commit/104e69bc419533abdfbe0b200ef3aaba1c27c73b) by Zoltan K).
- fix(inventory): add hubble to extra_hosts for local /etc/hosts ([55d8a7a](https://github.com/kecsi-san/homelab/commit/55d8a7a2f35bb2bd472ca74fa1b7f17236fd1325) by Zoltan K).
- fix(k8s): add Authentik ProxyProvider for Hubble UI ([5dd5cd9](https://github.com/kecsi-san/homelab/commit/5dd5cd9e8783a0f6d277fab6915577fc96745b76) by Zoltan K).
- fix(k8s): gate Hubble UI behind Authentik SSO ([2721a09](https://github.com/kecsi-san/homelab/commit/2721a09f63a764bd2d6912139863d82235784f79) by Zoltan K).
- fix(setup_kube-extra): pin helm to @3, was unpinned and drifted to v4 ([77c9efa](https://github.com/kecsi-san/homelab/commit/77c9efab68fe2c1c1c3732f837b6b670d4cee1d0) by Zoltan K).
- fix(k8s): track letsencrypt-prod ClusterIssuer in git ([7d49f54](https://github.com/kecsi-san/homelab/commit/7d49f548db86ba4519f8c4d3e5fb809f0149b9ae) by Zoltan K).
- fix(k3s): add missing letsencrypt-prod ClusterIssuer ([a36b9ee](https://github.com/kecsi-san/homelab/commit/a36b9ee90b3c8a8c499b0ffc54b9d4b6f4709814) by Zoltan K).
- fix(forgejo-runner): bump PVC 1Gi -> 2Gi to resolve KubePersistentVolumeFillingUp ([fa6d9a7](https://github.com/kecsi-san/homelab/commit/fa6d9a79a5737c27fef6181aaf4322cbcd7d1958) by Zoltan K).
- fix(setup_email-server): fix Dovecot 2.4 config issues and tidy certbot ([d077794](https://github.com/kecsi-san/homelab/commit/d077794331ae112182da9ac5b216d475ca9e2381) by Zoltan K).
- fix(setup_security-tools): remove AIDE from kube nodes ([4fba2b9](https://github.com/kecsi-san/homelab/commit/4fba2b999831716c9f9c40db93d1d08f4b436491) by Zoltan K).
- fix(setup_security-tools): exclude /backups from AIDE scans ([01bbe8f](https://github.com/kecsi-san/homelab/commit/01bbe8f5400cea4fb239f7f57b897a3a064fd563) by Zoltan K).
- fix(setup_python-uv): add hvac extra for community.hashi_vault lookups ([0f36421](https://github.com/kecsi-san/homelab/commit/0f3642135b000295dde416b4fe1b2a05ce5eb98a) by Zoltan K).
- fix(garage): shrink PVC 10Gi -> 1Gi, unused/oversized ([8a56867](https://github.com/kecsi-san/homelab/commit/8a56867089013800a964aeb4862da5893d66656e) by Zoltan K).
- fix(aide): codify SILENTREPORTS=yes, applied live earlier this session ([382de87](https://github.com/kecsi-san/homelab/commit/382de87df9100163fe36cca79dd483cd1b14fd17) by Zoltan K).
- fix(aide): exclude kube dynamic storage paths, poll aideinit properly ([ff95615](https://github.com/kecsi-san/homelab/commit/ff95615747eae18164687f780ea38125d7c2c30e) by Zoltan K).
- fix(wikijs): correct jqPathExpressions syntax for DB_SSL_CA ignore ([a5bdf44](https://github.com/kecsi-san/homelab/commit/a5bdf44ae297d11a14f530e1598005a977ec749e) by Zoltan K).
- fix(wikijs): ignore DB_SSL_CA empty-string env value drift ([78c9bce](https://github.com/kecsi-san/homelab/commit/78c9bce2d1177b1ea2b27f503437c44b21d04d1e) by Zoltan K).
- fix(wikijs): ignore deployment.kubernetes.io/revision annotation ([3f801ac](https://github.com/kecsi-san/homelab/commit/3f801acabde2aa94cdb250ad12304e7eaa5d20bf) by Zoltan K).
- fix(cnpg-cluster): remove dead createDb typo from wikijs managed role ([037216d](https://github.com/kecsi-san/homelab/commit/037216d8632bf5d37c8c34958b5b5d07c23bdbd1) by Zoltan K).
- fix(cnpg-cluster): ignore CNPG's reconciliationLoop annotation churn ([ffac236](https://github.com/kecsi-san/homelab/commit/ffac23641cf2356df559cc78d5b305bc81e8c32a) by Zoltan K).
- fix(sealed-secrets): update Helm repo URL for bitnami-labs -> bitnami org rename ([8edccb9](https://github.com/kecsi-san/homelab/commit/8edccb9fe8ecab514523978ff9a992566ef837ea) by Zoltan K).
- fix(wikijs): migrate to externalPostgresql values for chart v3.0.0 ([696f4e1](https://github.com/kecsi-san/homelab/commit/696f4e14aeaf90e40c97f0e0b5630a7128038b7a) by Zoltan K).
- fix(security): replace real family names with generic examples ([48b0a7c](https://github.com/kecsi-san/homelab/commit/48b0a7c57fd6109152113b664b6c6613d1cc21af) by Zoltan K).
- fix(security): move sensitive EC2 data out of committed aws.yml ([cc7dc1b](https://github.com/kecsi-san/homelab/commit/cc7dc1b5208db6a632673af408ff0c780aa54714) by Zoltan K).
- fix(ci): install Ansible collections into the actual cached path ([8eb8d59](https://github.com/kecsi-san/homelab/commit/8eb8d59bc4ab85e5c5797b4179c07e18c15cf2f9) by Zoltan K).
- fix(configure_git): install git-lfs, fix templating, wire into local playbooks ([1eb94dc](https://github.com/kecsi-san/homelab/commit/1eb94dc35c6b87f3f4f2e722b42fc916185b3db8) by Zoltan K).
- fix(setup_email-server): escape % in dovecot-fts cron job ([4d5d7dd](https://github.com/kecsi-san/homelab/commit/4d5d7ddface8dc4b85fec2f9a174c86eba906d81) by Zoltan K).
- fix(setup_unbound): install unbound-anchor package for Debian 13+ ([abff576](https://github.com/kecsi-san/homelab/commit/abff576e5f73d2fe3d0df8fb8f35cb919b1ff68f) by Zoltan K).
- fix(aws): ec2 instance parameter sync ([9ecae12](https://github.com/kecsi-san/homelab/commit/9ecae120cdb0e38a55e846226f7a3ca0643296f8) by Zoltan K).
- fix(terraform): align ec2.tf with live state from reverse engineering ([bd5c36e](https://github.com/kecsi-san/homelab/commit/bd5c36ee91a2c50fc37200c75541adb3438f429b) by Zoltan K).
- fix(terraform): replace deprecated dynamodb_table with use_lockfile, bump version to ~>1.10 ([c11c9c6](https://github.com/kecsi-san/homelab/commit/c11c9c6312ce47714207e0dec35eb6f4c437fd37) by Zoltan K).
- fix(ansible-lint): add name to import_tasks in setup_email-server; add justfile TODO ([7f8e28f](https://github.com/kecsi-san/homelab/commit/7f8e28f76e601261169f525c19ab16d3405312ae) by Zoltan K).
- fix(argocd): resolve OutOfSync for volsync, wikijs, cnpg-cluster ([434566c](https://github.com/kecsi-san/homelab/commit/434566c3feac71bb196fff08476472ad29f462c3) by Zoltan K).
- fix: typo in README.md ([744a312](https://github.com/kecsi-san/homelab/commit/744a312fb320ec1298873cba260161d90989280c) by Zoltan K).
- fix(kromgo): use ALERTS metric for alert count, exclude Watchdog and InfoInhibitor by name ([bb2870b](https://github.com/kecsi-san/homelab/commit/bb2870bddb134c34c281cc8f12fa9cdf79eee5d1) by Zoltan K).
- fix(security-tools): run aideinit in background to avoid blocking playbook ([baa85f9](https://github.com/kecsi-san/homelab/commit/baa85f970fcd4381b8d638e1cae81be85f8d38f9) by Zoltan K).
- fix(cloudflare-zone): use Jinja2 dict expression for body to preserve int/bool types ([dbd55ba](https://github.com/kecsi-san/homelab/commit/dbd55bae36f3c92c870fdd574e2708bd21bce508) by Zoltan K).
- fix(cloudflare-zone): cast ttl to int and proxied to bool for CF API ([35b2734](https://github.com/kecsi-san/homelab/commit/35b27344acb534a2886634aa3a950ffacdcd8e64) by Zoltan K).
- fix(cloudflare-zone): split DNS and settings tokens; ECH uses cloudflare_settings_token ([88c2bb4](https://github.com/kecsi-san/homelab/commit/88c2bb49af704e3d06b6f02e6f81461eb8408e6a) by Zoltan K).
- fix(cloudflare-zone): check_mode safe on ECH GET task ([241334f](https://github.com/kecsi-san/homelab/commit/241334fa782d3ec001438b19328d3c7e5c70a068) by Zoltan K).
- fix(cloudflare-zone): check_mode safe GET; guard create/update against skipped items ([b9c9541](https://github.com/kecsi-san/homelab/commit/b9c9541f7fec0d1612c6e83cf28693a0968d676d) by Zoltan K).
- fix(k3s/wikijs): tighten Authentik redirect URI to strict with real UUID ([dacc26f](https://github.com/kecsi-san/homelab/commit/dacc26f61a063c1bf2d508a097cdf7830c0c55de) by Zoltan K).
- fix(k3s/argocd): add app.kubernetes.io/part-of label to oidc secret template ([e2593fc](https://github.com/kecsi-san/homelab/commit/e2593fc71a208f6938880caf5b018db1217eb1ca) by Zoltan K).
- fix(kromgo): make it public, via cloudflare proxy so we can display badges in GH readme.md ([d4c10c0](https://github.com/kecsi-san/homelab/commit/d4c10c0be68739852724cfc54ed7f544532faedc) by Zoltan K).
- fix(ansible/k8s-nodes): mask openipmi.service on HP iLO nodes ([97db3cd](https://github.com/kecsi-san/homelab/commit/97db3cdc44244441fbbbff1fb7a3b02956a1a72b) by Zoltan K).
- fix(ansible/security): add AIDE and initialize baseline database ([85c7634](https://github.com/kecsi-san/homelab/commit/85c7634befb28e9e8aee38eb081503540fed20c4) by Zoltan K).
- fix(k8s/volsync): disable kube-rbac-proxy auth on metrics endpoint ([1081550](https://github.com/kecsi-san/homelab/commit/10815504032c1d425ea86ddaed0c94d9e325690a) by Zoltan K).
- fix(k8s/cnpg-cluster): ignore ArgoCD tracking label drift on Cluster resource ([b06dd86](https://github.com/kecsi-san/homelab/commit/b06dd861773180f75c67acdceb1bad1cc8cb30c3) by Zoltan K).
- fix(k8s/ntfy): set Recreate rollout strategy for RWO PVC ([ef7b480](https://github.com/kecsi-san/homelab/commit/ef7b480539df47e9fee994e383d300975bf2a120) by Zoltan K).
- fix(k3s/homepage): resolve NOT FOUND for forgejo and authentik ([9fa0606](https://github.com/kecsi-san/homelab/commit/9fa0606d82e2472cd69471ee48b5c4e8206794a8) by Zoltan K).
- fix(k8s/homepage): remove invalid openmetrics top-bar widgets; add Kromgo service ([fcbcad2](https://github.com/kecsi-san/homelab/commit/fcbcad2e59ae97904ffe6cae3b8ef779117cbab9) by Zoltan K).
- fix(k8s/homepage): resolve NOT FOUND status for raw-manifest services ([70d2fc7](https://github.com/kecsi-san/homelab/commit/70d2fc7646782fae7af54e50a12029eafb77bab8) by Zoltan K).
- fix(kromgo): badges definition update and gallery enabled ([68bd830](https://github.com/kecsi-san/homelab/commit/68bd830552993602964e85517716ca9133759b6d) by Zoltan K).
- fix(k8s/homepage): switch Kromgo to openmetrics; fix app labels; add k8s widget ([c944c2f](https://github.com/kecsi-san/homelab/commit/c944c2f2fcc8e352b142aa6385c068ae860b47fb) by Zoltan K).
- fix(homepage): remove unsupported display:compact from customapi widgets ([dfecaa0](https://github.com/kecsi-san/homelab/commit/dfecaa079b8398e092d584312cf225195cf022bb) by Zoltan K).
- fix(k3s/homepage): enable Kubernetes cluster mode for widget ([028c6e4](https://github.com/kecsi-san/homelab/commit/028c6e4deeac49775fd4a5c84a06fab98eac6b18) by Zoltan K).
- fix(homepage): use internal service URL for Kromgo customapi widgets ([219725c](https://github.com/kecsi-san/homelab/commit/219725c97520fa3966a0efd74c5f1d2032c34543) by Zoltan K).
- fix(k3s/forgejo): add Recreate strategy and hostAlias for Authentik ([42210d7](https://github.com/kecsi-san/homelab/commit/42210d7587ace249433e1922f7aca5895fbdd246) by Zoltan K).
- fix(k3s/forgejo): add hostAlias for authentik.k3s.kecskemethy.org ([5809ed6](https://github.com/kecsi-san/homelab/commit/5809ed6e11efaba8117301599a06585e9088f766) by Zoltan K).
- fix(k3s/traefik): correct service type path to service.spec.type ([595522f](https://github.com/kecsi-san/homelab/commit/595522f92b8a1404ba2e9a66a830ac37743c67cb) by Zoltan K).
- fix(etc-hosts): add retired_hosts_patterns; fix wikijs→wiki domain ([3bf8f66](https://github.com/kecsi-san/homelab/commit/3bf8f669451bda4eaab819da1a6269719b330377) by Zoltan K).
- fix(dns): remove k3s AAAA override; fix Windows hosts and WSL2 extra_hosts ([f310e38](https://github.com/kecsi-san/homelab/commit/f310e38b0e386bdb45fc0fc70be9a97c8e827178) by Zoltan K).
- fix(homepage): update Kromgo widget field from result to message ([8129f4c](https://github.com/kecsi-san/homelab/commit/8129f4ced1745be0e349da6f511f65fef5aa9d13) by Zoltan K).
- fix(kromgo): upgrade to home-operations/kromgo:0.11.1 with correct config format ([5dc78ef](https://github.com/kecsi-san/homelab/commit/5dc78efdd224fb4f349c0454dcad6f82cf202a2f) by Zoltan K).
- fix(kromgo): restore prometheus_url in config.yaml ([45c313c](https://github.com/kecsi-san/homelab/commit/45c313c8ed1ddd57847a7b894c0f113f4530dfb7) by Zoltan K).
- fix(kromgo): pass PROMETHEUS_URL as env var; remove from config file ([bb1e22d](https://github.com/kecsi-san/homelab/commit/bb1e22d49a1f0f965e7dcfada50238be41571dc7) by Zoltan K).
- fix(kromgo): correct config mount path to /kromgo/config.yaml ([2c83d8d](https://github.com/kecsi-san/homelab/commit/2c83d8d44b06a490f687e6df38f0403b815b5995) by Zoltan K).
- fix(kromgo): correct image to ghcr.io/kashalls/kromgo:0.3.1 ([773a353](https://github.com/kecsi-san/homelab/commit/773a353696d8c85ae6ef86715fda97bb9e0ca50e) by Zoltan K).
- fix(wikijs): remove debug patches, clean up OIDC login fix ([d30b5e4](https://github.com/kecsi-san/homelab/commit/d30b5e45647076b8f54318906bdbb70b528dfe59) by Zoltan K).
- fix(wikijs): change Authentik issuer_mode to per_provider ([991e80d](https://github.com/kecsi-san/homelab/commit/991e80d8ba9fa1ab9ab4d4eae7990effa60a52b6) by Zoltan K).
- fix(wikijs): patch passport-openidconnect session state store ([3f70705](https://github.com/kecsi-san/homelab/commit/3f70705983cbb025d2b6deac9e334ee455e62380) by Zoltan K).
- fix(wiki): correct Authentik redirect_uri to Wiki.js UUID-based callback ([b31edf4](https://github.com/kecsi-san/homelab/commit/b31edf44448a6f149c64b2ec74a5bfc4017b5a84) by Zoltan K).
- fix(monitoring): replace Traefik chart ServiceMonitor with raw one ([82bea88](https://github.com/kecsi-san/homelab/commit/82bea8811d071aff94a7aee82319eb6c42374746) by Zoltan K).
- fix(monitoring): add traefik-traefik label to metrics service ([19e51ff](https://github.com/kecsi-san/homelab/commit/19e51ff27e26a664c2c4b24472810c3f58533127) by Zoltan K).
- fix(monitoring): fix dashboards + Traefik metrics service ([ba293a4](https://github.com/kecsi-san/homelab/commit/ba293a47d24cbc924b1b329ebfeae26398c59ad9) by Zoltan K).
- fix(monitoring): set serviceMonitorSelectorNilUsesHelmValues: false ([543376a](https://github.com/kecsi-san/homelab/commit/543376a1847322b3a4f50a7e9843534700365571) by Zoltan K).
- fix(monitoring): add Longhorn ServiceMonitor as raw manifest ([94384ca](https://github.com/kecsi-san/homelab/commit/94384ca31d9543bf6d5678acbe430393533bc0e7) by Zoltan K).
- fix(monitoring): include name label in ntfy alert message body ([44b0d6e](https://github.com/kecsi-san/homelab/commit/44b0d6e287bc633b16e1d407c4d55b8c3e3025bd) by Zoltan K).
- fix(monitoring): fix non-ASCII x in ntfy title header; add PYTHONUNBUFFERED ([2c243be](https://github.com/kecsi-san/homelab/commit/2c243be4a9f1b8dba82545697eeff00c6be4355b) by Zoltan K).
- fix(argocd): use knownTypeFields for terminatingReplicas; add hostNetwork ignore ([927bb7e](https://github.com/kecsi-san/homelab/commit/927bb7eaecf43b00070946b6a7519fd077c99e63) by Zoltan K).
- fix(argocd): add Deployment+ReplicaSet to terminatingReplicas ignoreDifferences ([fb488a4](https://github.com/kecsi-san/homelab/commit/fb488a4328e536e73886c17706b8b69139c2b92d) by Zoltan K).
- fix(authentik+argocd): grant_types for Grafana; global terminatingReplicas ignore ([978bcff](https://github.com/kecsi-san/homelab/commit/978bcffe4e0ac924e5cfd2d137267a2465044490) by Zoltan K).
- fix(argocd): add global resource customizations for monitoring.coreos.com ([d011b9b](https://github.com/kecsi-san/homelab/commit/d011b9b8563fa7739d3378f9260014c105154e83) by Zoltan K).
- fix(monitoring): disable PKCE in Grafana OAuth2 config ([69754cb](https://github.com/kecsi-san/homelab/commit/69754cba3dc9abcc174a215629d5d0f48f8cfce3) by Zoltan K).
- fix(monitoring): restore ServerSideApply + add CRD ignoreDifferences for KPS ([380f41c](https://github.com/kecsi-san/homelab/commit/380f41c5c74ccdc51b158f9ec59d1d59103ae55f) by Zoltan K).
- fix(monitoring): add ignoreDifferences for terminatingReplicas on KPS ([efacbd6](https://github.com/kecsi-san/homelab/commit/efacbd650bf02bca0de2aa9fec027049ed563896) by Zoltan K).
- fix(monitoring): remove ServerSideApply; fix node-exporter port conflict ([9838534](https://github.com/kecsi-san/homelab/commit/9838534bc2c760b16cc8b3c83a5280fe4f5ee168) by Zoltan K).
- fix(monitoring): bump chart versions to latest available ([574e219](https://github.com/kecsi-san/homelab/commit/574e2199bb50baf29338ee717c84dabe9312f8e8) by Zoltan K).
- fix+docs: redact real email from kubeseal example; add hardening TODOs ([cc80c37](https://github.com/kecsi-san/homelab/commit/cc80c37862a214224fa20d53ed800d738b340989) by Zoltan K).
- fix(traefik): move redirections under ports.web.http for chart v40 compatibility ([5ffbfa8](https://github.com/kecsi-san/homelab/commit/5ffbfa81653c57e7daab4f2ce97fdd72e6f20323) by Zoltan K).
- fix(argocd): use email as RBAC subject for admin role ([607f794](https://github.com/kecsi-san/homelab/commit/607f79411341cb99ce5b23f3e3338262740615de) by Zoltan K).
- fix(argocd): add required label to oidc secret ([910d32d](https://github.com/kecsi-san/homelab/commit/910d32d446ecc3a7e51191f87a0ba0f929b925ca) by Zoltan K).
- fix(argocd): set server.url so redirect URI uses https ([6e6cda9](https://github.com/kecsi-san/homelab/commit/6e6cda9a7c9eaed4cce35f7cafd80f23945eaf40) by Zoltan K).
- fix(argocd): use per_provider issuer mode in Authentik blueprint ([a711de0](https://github.com/kecsi-san/homelab/commit/a711de03dee89cda26e32d8e9476fb4d21131580) by Zoltan K).
- fix(argocd): manage oidc config via raw manifests ([1a908de](https://github.com/kecsi-san/homelab/commit/1a908de931a55f3fa06d692d1b1cf8890ad4a425) by Zoltan K).
- fix(backstage): remove scope option, use default OIDC scopes ([d058b42](https://github.com/kecsi-san/homelab/commit/d058b427f05520fb20c79f77876eefc644993ec6) by Zoltan K).
- fix(backstage): use emailLocalPartMatchingUserEntityName resolver ([c6d37db](https://github.com/kecsi-san/homelab/commit/c6d37db0b59faa61e6a679d4590741b604e8e791) by Zoltan K).
- fix(backstage): add auth.providers to Helm appConfig ([dbabdaf](https://github.com/kecsi-san/homelab/commit/dbabdaf9c450d0177d68bbd3fdcdb56b3e245392) by Zoltan K).
- fix(homepage): remove broken kubernetes widget, fix backstage icon ([19abbe2](https://github.com/kecsi-san/homelab/commit/19abbe28c23ec3799c6c8ac05959c78559dfc320) by Zoltan K).
- fix(forgejo-runner): use Recreate strategy for RWO PVC ([725d7cd](https://github.com/kecsi-san/homelab/commit/725d7cd556a9433ee7aeb2d311279cf9c261c89b) by Zoltan K).
- fix(backstage): move OIDC provider config into custom image app-config ([659a0d1](https://github.com/kecsi-san/homelab/commit/659a0d142c3ba4a575c02b813bc06b7e40966152) by Zoltan K).
- fix(ci): use host network + TCP Docker host for job containers ([110981d](https://github.com/kecsi-san/homelab/commit/110981dc7695905e4dadefcbf9d01206434e5b9b) by Zoltan K).
- fix(backstage): use schema-based plugin division to avoid createdb permission ([22a26f1](https://github.com/kecsi-san/homelab/commit/22a26f13acef382e396a7465929747877ee93986) by Zoltan K).
- fix(dns): use ::1 for k3s AAAA wildcard, fd42::1 for k8s only ([ad4d29a](https://github.com/kecsi-san/homelab/commit/ad4d29a2b4f9efbbdd06a3abbf923abf997b2750) by Zoltan K).
- fix(dns): use RouterOS type field to distinguish A/AAAA records; migrate ::1 to fd42::1 ([036f20c](https://github.com/kecsi-san/homelab/commit/036f20cdb3a26ba7ceb3d3c59873b53e7f8a50ad) by Zoltan K).
- fix(dns): add wildcard AAAA overrides to block Cloudflare IPv6 on LAN ([3489d8d](https://github.com/kecsi-san/homelab/commit/3489d8d6b2a0f835f087c8502fd6e116f06676ef) by Zoltan K).
- fix(forgejo): increase memory limit 512Mi → 1Gi to prevent OOMKill ([b01235e](https://github.com/kecsi-san/homelab/commit/b01235eb603f018e8b1767dfa24e161e533bb118) by Zoltan K).
- fix(forgejo-runner): chmod /data before register to fix PVC permissions ([2646c49](https://github.com/kecsi-san/homelab/commit/2646c49c1396016e5335e6fdf3f938d689f076ac) by Zoltan K).
- fix(forgejo-runner): set workingDir /data on init container ([af4f3a9](https://github.com/kecsi-san/homelab/commit/af4f3a9aaaaf94267bf0ced55ab85e7519a518f6) by Zoltan K).
- fix(forgejo-runner): cd /data before register to write .runner to PVC ([894c188](https://github.com/kecsi-san/homelab/commit/894c188a833d5f90e4262caa37a90b298984e2c2) by Zoltan K).
- fix(forgejo-runner): persist runner data on Longhorn PVC ([f66d8b0](https://github.com/kecsi-san/homelab/commit/f66d8b0a19b045b5690dfc7e60e3605dd2a38482) by Zoltan K).
- fix(forgejo-runner): use wget to wait for DinD instead of docker CLI ([370071c](https://github.com/kecsi-san/homelab/commit/370071c374823876914a5bf047adefc14733d154) by Zoltan K).
- fix(forgejo-runner): use tcp://localhost:2375 for DinD socket ([4f7eac3](https://github.com/kecsi-san/homelab/commit/4f7eac36933273a76a952cac7cd2d2a93c40aebb) by Zoltan K).
- fix(forgejo-runner): use github.com repo URL in ArgoCD app ([146c084](https://github.com/kecsi-san/homelab/commit/146c084efad4fcf0c7a21577b3bdd5d8e3beb756) by Zoltan K).
- fix(k8s/authentik): use per_provider issuer_mode for Headlamp OIDC ([3e46e9b](https://github.com/kecsi-san/homelab/commit/3e46e9bbcc8ccf2fe23e21486c0f257ee8fa8e46) by Zoltan K).
- fix(k8s/traefik): disable kubernetesIngress provider ([871528e](https://github.com/kecsi-san/homelab/commit/871528e5acd3466f11e231c046b42db836e8006e) by Zoltan K).
- fix(k8s/traefik): enable allowCrossNamespace for cross-ns middleware refs ([ae58273](https://github.com/kecsi-san/homelab/commit/ae5827326c47c75b61f67178f99c093fb310e8bc) by Zoltan K).
- fix(forgejo): use Recreate rollout strategy to avoid LevelDB queue lock ([af6d5e7](https://github.com/kecsi-san/homelab/commit/af6d5e7984222c7994bab8a781f92bfa68b5a4c5) by Zoltan K).
- fix(forgejo): disable remember-me to prevent silent re-login after sign-out ([952ca98](https://github.com/kecsi-san/homelab/commit/952ca98833b7140c83f9b5b1fd44fbddfb1a8f97) by Zoltan K).
- fix(authentik/forgejo): add invalidation_flow to blueprint, fix job app.ini path ([e9aa67c](https://github.com/kecsi-san/homelab/commit/e9aa67cf9758cc82ed4ba4ed11fb83e698e6b5b0) by Zoltan K).
- fix(configure_ntp): switch from ntpd to chrony (Debian 13 removed ntp package) ([47564f8](https://github.com/kecsi-san/homelab/commit/47564f8141a4810ae357c20ed57da006af61e178) by Zoltan K).
- fix(k8s/authentik): replace bundled Redis with standalone official image ([b3bbf17](https://github.com/kecsi-san/homelab/commit/b3bbf17ac679b9527be7eb23e2f9e3d8b8f54205) by Zoltan K).
- fix(k8s/authentik): override Redis image registry to registry.bitnami.com ([adfc3d5](https://github.com/kecsi-san/homelab/commit/adfc3d5fe538403c742e18ff1e2d1aed8bcadb84) by Zoltan K).
- fix(k3s/homepage): add Forgejo to Platform section, fix ArgoCD icon ([807b09a](https://github.com/kecsi-san/homelab/commit/807b09accbad5286d78d45a61c8c460f691d5f8b) by Zoltan K).
- fix(forgejo): update admin SealedSecret username from admin to kecsi ([746b4cd](https://github.com/kecsi-san/homelab/commit/746b4cd0a1d275b762e43457428e3fbc4ea955ff) by Zoltan K).
- fix(forgejo): use GITEA__ env vars for config, mount PVC at /var/lib/gitea ([0f30752](https://github.com/kecsi-san/homelab/commit/0f30752be8d92478c96bec91da2748a217014ddd) by Zoltan K).
- fix(forgejo): split image registry from repository to prevent Gitea chart prepending default registry ([45ad1bd](https://github.com/kecsi-san/homelab/commit/45ad1bdc6fc4eb2980a1f8331f9bd655767fbc97) by Zoltan K).
- fix(cnpg): reduce postgres PVC size from 10Gi to 2Gi ([24b7aba](https://github.com/kecsi-san/homelab/commit/24b7aba42016be89d2c260ac189fc53c1ebb7590) by Zoltan K).
- fix(cnpg): add username key to forgejo-db-credentials SealedSecret in postgres ns ([d8ae86a](https://github.com/kecsi-san/homelab/commit/d8ae86a91c696477ec6dc1ea83b5081c4a463df3) by Zoltan K).
- fix(cnpg): add RespectIgnoreDifferences to fix terminatingReplicas schema error ([ed85c1e](https://github.com/kecsi-san/homelab/commit/ed85c1e9961f8b084d98caf99ddfa9b2e31a29d2) by Zoltan K).
- fix(cnpg): add ServerSideApply to resolve oversized CRD annotation ([b282989](https://github.com/kecsi-san/homelab/commit/b28298907aa4e13b798d62754525a50bb988e44f) by Zoltan K).
- fix(homepage): remove background blur to improve image visibility ([c5913cf](https://github.com/kecsi-san/homelab/commit/c5913cf4ad5c1561f50f46d7ecb27279ba12cbc1) by Zoltan K).
- fix(homepage): correct Glance logo URL (docs/logo.png not docs/images/logo.png) ([5529402](https://github.com/kecsi-san/homelab/commit/5529402de6d5836892123c9aca6e5e5faef78fac) by Zoltan K).
- fix(secrets): add yamllint disable-line comments to SealedSecret encrypted data ([08657ec](https://github.com/kecsi-san/homelab/commit/08657ecbc20c7816333fcfdd3c62ba933e19663b) by Zoltan K).
- fix(volsync): add RespectIgnoreDifferences to fix terminatingReplicas schema error ([62d75c2](https://github.com/kecsi-san/homelab/commit/62d75c252c584932218086936fc41a0c77216344) by Zoltan K).
- fix(gatus): correct env format to dict and set Recreate strategy ([184819c](https://github.com/kecsi-san/homelab/commit/184819c7703a25f3bc91c0d6607f64c31db2c1a3) by Zoltan K).
- fix(kube-gitops): restore real domain in operational manifests ([3233954](https://github.com/kecsi-san/homelab/commit/32339542cb25c8cd03b7262bb423160c7d47b00d) by Zoltan K).

## [v0.1.0](https://github.com/kecsi-san/homelab/releases/tag/v0.1.0) - 2026-05-10

<small>[Compare with first commit](https://github.com/kecsi-san/homelab/compare/c22df6e9f9d59fa012e41442e65b424006cff498...v0.1.0)</small>

### Fixed

- fix(docs): push Headlamp label below icon with leading newlines ([74f2842](https://github.com/kecsi-san/homelab/commit/74f2842fb81182f3e78303be839ebfe78cc2bae3) by Zoltan K).
- fix(docs): resize headlamp icon to 85% (350x435) by resizing the PNG ([70b24fe](https://github.com/kecsi-san/homelab/commit/70b24fe5cced7ed903ec75ffc8ce93a00237910e) by Zoltan K).
- fix(docs): scale Headlamp icon to 85% ([4578161](https://github.com/kecsi-san/homelab/commit/4578161beb369e8231293c2ed22444183558998e) by Zoltan K).
- fix(docs): move GitHub node to right side of diagram ([9bc1926](https://github.com/kecsi-san/homelab/commit/9bc1926613ce27a0653b673d5aac472be8971635) by Zoltan K).
- fix(docs): fix custom icon path + force Nodes cluster above sub-clusters ([e1e3225](https://github.com/kecsi-san/homelab/commit/e1e3225610bfdf7dc944e7797bfb24a0587c900f) by Zoltan K).
- fix(longhorn): add dataLocality best-effort + WaitForFirstConsumer ([409962e](https://github.com/kecsi-san/homelab/commit/409962eb7899537d1d25604090511bb1ce0ea317) by Zoltan K).
- fix(mikrotik-dns): replace k8s subdomain wildcard with domain-level wildcard ([b8eb302](https://github.com/kecsi-san/homelab/commit/b8eb30287979f794ff7a8e440c0e9dce87eb2b7e) by Zoltan K).
- fix(lint): capitalize handler names to satisfy name[casing] rule ([5f8a9ef](https://github.com/kecsi-san/homelab/commit/5f8a9ef3c4478fc799101c1caef1915cd6d370a0) by Zoltan K).
- fix(tls): replace wildcard cert with per-service certs, remove idleTimeout ([ff18cc0](https://github.com/kecsi-san/homelab/commit/ff18cc05b46dfdc88cc3b5eddaff6cfdc3fd6cee) by Zoltan K).
- fix(k3s): rename kubeconfig context to admin@k3s automatically ([5a2dded](https://github.com/kecsi-san/homelab/commit/5a2dded981b747cebe1703b8fc65028bef579caa) by Zoltan K).
- fix(post-k8s): rename kubeconfig context to admin@k8s automatically ([5850838](https://github.com/kecsi-san/homelab/commit/58508381f9450153b10431588d1f802999a6f868) by Zoltan K).
- fix(volsync): switch copyMethod from Snapshot to Clone ([b1bb88b](https://github.com/kecsi-san/homelab/commit/b1bb88b777e3054218557401bea1f4927cdc4960) by Zoltan K).
- fix(volsync): regenerate restic sealed secrets cleanly (no manual copy-paste) ([2a37a57](https://github.com/kecsi-san/homelab/commit/2a37a57656c08fce1413519ef97218fe507d2806) by Zoltan K).
- fix(volsync): reseal restic secrets against k8s cluster (not k3s) ([66cb368](https://github.com/kecsi-san/homelab/commit/66cb36843f460c686ed16ee0515cd1de7a8e92c4) by Zoltan K).
- fix(python-uv): add librouteros to ansible-core extras; use --force on install ([fb76fe7](https://github.com/kecsi-san/homelab/commit/fb76fe76b285e285b7d18c7efe7e0c4a63a30aed) by Zoltan K).
- fix(dns): rename backup.kinet.local → backups.kinet.local ([05c6e6e](https://github.com/kecsi-san/homelab/commit/05c6e6efa8d899356b8f67c4fb99093a5eb44fb3) by Zoltan K).
- fix(traefik): disable HTTP/2 to prevent Firefox H2 connection coalescing ([051c671](https://github.com/kecsi-san/homelab/commit/051c671a8e9ad62c4eb10f6e9316099190e35648) by Zoltan K).
- fix(volsync): remove ServerSideApply to use lenient diff path ([9cd50e4](https://github.com/kecsi-san/homelab/commit/9cd50e41a5fc2eb7fd7c178b9699c786734ad8e7) by Zoltan K).
- fix(volsync): ignore terminatingReplicas field missing from ArgoCD schema ([a723089](https://github.com/kecsi-san/homelab/commit/a7230897221dad3637618e256817de43b4fc11a0) by Zoltan K).
- fix(gatus): use strategy.type Recreate for RWO PVC compatibility ([c4315b4](https://github.com/kecsi-san/homelab/commit/c4315b4573fcce0337910a8d08a3f137ea17ec43) by Zoltan K).
- fix(garage): add explicit command entrypoint for garage binary ([79f7160](https://github.com/kecsi-san/homelab/commit/79f716090544144b766556bae8c351fc3103c89f) by Zoltan K).
- fix: correct garage config path, volsync CRD schema, gatus recreate strategy ([669ad2f](https://github.com/kecsi-san/homelab/commit/669ad2fa72cbf2a80551cb5a4d1465af272c22df) by Zoltan K).
- fix(traefik): set 20s idle connection timeout to prevent stale H2 connections ([21db195](https://github.com/kecsi-san/homelab/commit/21db195607bc9cf4a41a1454dd8ee1dab408e528) by Zoltan K).
- fix(argocd): patch insecure mode in post-k8s.yml after Kubespray install ([a95ac2d](https://github.com/kecsi-san/homelab/commit/a95ac2d3d712d8a4e453008840c70afb4a3d8e78) by Zoltan K).
- fix(longhorn): disable pre-upgrade hook for ArgoCD fresh install ([a26033f](https://github.com/kecsi-san/homelab/commit/a26033f38a56318bf4d22f77e65566220abee311) by Zoltan K).
- fix(k8s): fix Cilium CNI for reliable automated cluster rebuild ([2c5b3a2](https://github.com/kecsi-san/homelab/commit/2c5b3a208c3e721f74ede8febd8dc71127dd730b) by Zoltan K).
- fix(router): fix mikrotik-dns playbook and role for first-run reliability ([fd47d2b](https://github.com/kecsi-san/homelab/commit/fd47d2b31515a9038f5259a67e7040fd988a03e1) by Zoltan K).
- fix(k8s): use cluster.local as internal DNS domain ([6ac27a4](https://github.com/kecsi-san/homelab/commit/6ac27a44c0cb0518c8ad62511681ac7adae81321) by Zoltan K).
- fix(security): remove hardcoded email from ClusterIssuer manifests ([df4b226](https://github.com/kecsi-san/homelab/commit/df4b226c1b766b804dfe6fca3d100117a27901ae) by Zoltan K).
- fix(uv): add netaddr to ansible-core tool extras (required by Kubespray) ([0e4a1bf](https://github.com/kecsi-san/homelab/commit/0e4a1bf3d54de90a968921888e0fe7921756e397) by Zoltan K).
- fix(uv): add ~/.local/bin to PATH via blockinfile instead of update-shell ([94001a6](https://github.com/kecsi-san/homelab/commit/94001a6929b7b29ef7ab0cca3ad4e7555f4d7cfd) by Zoltan K).
- fix(uv): run uv tool update-shell to add ~/.local/bin to PATH ([f7777b3](https://github.com/kecsi-san/homelab/commit/f7777b3cdc72b69080fb0774754b94345fe0704e) by Zoltan K).
- fix(uv): install ansible-core instead of ansible meta-package ([ee6db96](https://github.com/kecsi-san/homelab/commit/ee6db96db95fbc49c7355a500212fbc45ab17af2) by Zoltan K).
- fix(uv): pin ansible to >=11,<12 for Kubespray 2.31 compatibility ([18e0b9a](https://github.com/kecsi-san/homelab/commit/18e0b9af5f3a96eb0184a28fea2e30e2913d020d) by Zoltan K).
- fix(k3s): run Traefik as root for privileged port binding on WSL2 ([395d557](https://github.com/kecsi-san/homelab/commit/395d5578660fbdc19d9fb141c348b39f322c7a85) by Zoltan K).
- fix(k3s): use Recreate strategy for Traefik with hostNetwork ([75ca7da](https://github.com/kecsi-san/homelab/commit/75ca7da6085deeecb6b17fb6e5841ee4020dced9) by Zoltan K).
- fix(k3s): bind Traefik to ports 80/443 with NET_BIND_SERVICE for hostNetwork ([655540c](https://github.com/kecsi-san/homelab/commit/655540ca0f0cca088897e0f2788845f66cba4dd7) by Zoltan K).
- fix(k3s): change Traefik metrics port to 9101 (9100 taken by node-exporter) ([e7b7a76](https://github.com/kecsi-san/homelab/commit/e7b7a7687ba2c8c958f6b5566fe94da744bfcb5d) by Zoltan K).
- fix(k3s): correct hostNetwork to top-level key in Traefik values ([1c0096d](https://github.com/kecsi-san/homelab/commit/1c0096d7a36c71a0755c2e9cc3d6a3eec82ec6e6) by Zoltan K).
- fix(k3s): use hostNetwork+ClusterIP for Traefik on WSL2 mirrored mode ([d1190d7](https://github.com/kecsi-san/homelab/commit/d1190d7106f4a13b7abc714f837372d4ecad5b17) by Zoltan K).
- fix(k3s): add hostPort to Traefik for WSL2 mirrored mode ([02094da](https://github.com/kecsi-san/homelab/commit/02094da95b33c2a65715a72c07e52091bb47b4a4) by Zoltan K).
- fix(ci): pass RENOVATE_REPOSITORIES so self-hosted Renovate finds the repo ([065b32e](https://github.com/kecsi-san/homelab/commit/065b32e975b77b7a4e074a3d511523443d85174f) by Zoltan K).
- fix(ci): pin renovatebot/github-action to v46.1.13 (no major tags published) ([4550107](https://github.com/kecsi-san/homelab/commit/4550107e69c25bfe4c6b3d3765067468914f211a) by Zoltan K).
- fix(ci): correct renovatebot/github-action version to v46 ([807528c](https://github.com/kecsi-san/homelab/commit/807528cc0ff696567d7e9c4257a0c4b2f73d459e) by Zoltan K).
- fix: correct Traefik dashboard URL in Homepage to include /dashboard/ path ([9824a62](https://github.com/kecsi-san/homelab/commit/9824a62217e703160cdf75f27ec0380dec961119) by Zoltan K).
- fix: set HOMEPAGE_ALLOWED_HOSTS env var for host validation ([e516428](https://github.com/kecsi-san/homelab/commit/e51642880ce48daa015030c5668f72b7a146382c) by Zoltan K).
- fix: allow homepage.kecskemethy.org in Homepage host validation ([6c18ab2](https://github.com/kecsi-san/homelab/commit/6c18ab294932fdb351c3c57dfb8687dd8a69e170) by Zoltan K).
- fix: disable HTTP/3 on k8s Traefik — kube-vip LB is TCP-only, QUIC/UDP fails ([3a66ee8](https://github.com/kecsi-san/homelab/commit/3a66ee85dd8b5196bf1209855dfa9328ecfd1fcf) by Zoltan K).
- fix: cloudflared metrics on 0.0.0.0 so liveness probe can reach it ([c011349](https://github.com/kecsi-san/homelab/commit/c011349c154fc4f0962c11b5e546ad5a75e7a62c) by Zoltan K).
- fix: update Traefik redirect syntax for chart v34 ([39381bf](https://github.com/kecsi-san/homelab/commit/39381bfad01fe2e415e87f36cef5fc7ca8451788) by Zoltan K).
- fix: remove apex domain from wildcard cert — wildcard is sufficient ([539fe25](https://github.com/kecsi-san/homelab/commit/539fe2545ccf61361211757c06acd9d858cbb689) by Zoltan K).
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

