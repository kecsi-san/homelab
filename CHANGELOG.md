# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

<!-- insertion marker -->
## Unreleased

<small>[Compare with latest](https://github.com/kecsi-san/ansible-env-setup/compare/c22df6e9f9d59fa012e41442e65b424006cff498...HEAD)</small>

### Fixed

- fix: cloudflared metrics on 0.0.0.0 so liveness probe can reach it ([632050e](https://github.com/kecsi-san/ansible-env-setup/commit/632050eb3ddb6682cfb7a827bb25258c91fbffaf) by Zoltan K).
- fix: update Traefik redirect syntax for chart v34 ([d583069](https://github.com/kecsi-san/ansible-env-setup/commit/d5830695bca94e92bcb3ee97fdeae273cb47528d) by Zoltan K).
- fix: remove apex domain from wildcard cert — wildcard is sufficient ([13a9ebf](https://github.com/kecsi-san/ansible-env-setup/commit/13a9ebf49817521d9c3f6bb9b961765e589c3305) by Zoltan K).
- fix: skip ansible-lint when vault password is unavailable (Dependabot) ([6171d8a](https://github.com/kecsi-san/ansible-env-setup/commit/6171d8a09aae80ca9c971534a89f24f60bab77b3) by Zoltan K).
- fix: break long line in configure_oh-my-posh theme selection ([43edd7b](https://github.com/kecsi-san/ansible-env-setup/commit/43edd7b700f2e496a143ca1d5b90c47d15c3302e) by Zoltan K).
- fix: resolve ansible-lint key-order and name-casing violations ([a4925fe](https://github.com/kecsi-san/ansible-env-setup/commit/a4925fea70c9c860d1bd7fcab5cfcadb7fb26357) by Zoltan K).
- fix: resolve macOS interpreter and uv upgrade path issues ([d73ba8d](https://github.com/kecsi-san/ansible-env-setup/commit/d73ba8de1866b0260bfed949d2365ad72a365911) by Zoltan K).
- fix: skip pip install task when uv_pip_packages is empty ([fd1632d](https://github.com/kecsi-san/ansible-env-setup/commit/fd1632d61f1d270c66cabb541428f9e8f04d48ff) by Zoltan K).
- fix: handler for sshd reload and serial upgrade ([18c6a2b](https://github.com/kecsi-san/ansible-env-setup/commit/18c6a2b4ded7c1c093bcd6858a212a4608b1aa5e) by Zoltan K).
- fix: make kubeseal completion non-fatal when controller is unreachable ([4282a6f](https://github.com/kecsi-san/ansible-env-setup/commit/4282a6fcbf691437ba087400e0bdebeb67d9345b) by Zoltan K).
- fix: replace helm_plugin module with command for helm-diff install ([d2ef92b](https://github.com/kecsi-san/ansible-env-setup/commit/d2ef92b1865c3f105930b0b4905f4d6be148e775) by Zoltan K).
- fix: resolve helm-diff missing and Python interpreter warnings ([7e73bdd](https://github.com/kecsi-san/ansible-env-setup/commit/7e73bddad43ac9174aa4a3bedf1cfc87a838a0d0) by Zoltan K).
- fix: update ansible-lint exclusions for renamed kubespray playbooks ([68387fb](https://github.com/kecsi-san/ansible-env-setup/commit/68387fb311e49f4586fa2e9ca402ac45adfcf939) by Zoltan K).
- fix: remove committed profile image and make it user-provided ([2ac9145](https://github.com/kecsi-san/ansible-env-setup/commit/2ac9145d5405acdd5f9a2095c2f293af1a3ec659) by Zoltan K).
- fix: make roles cross-platform (Linux + macOS) ([8538b75](https://github.com/kecsi-san/ansible-env-setup/commit/8538b754cf3989ca30ee13910abaf8e07b50fd7c) by Zoltan K).
- fix: add vault password file creation in CI ([886d91c](https://github.com/kecsi-san/ansible-env-setup/commit/886d91cc3801da8abc4428fee0575d5f645034c6) by Zoltan K).
- fix: exclude .venv from yamllint and fix collections_path for CI ([be52435](https://github.com/kecsi-san/ansible-env-setup/commit/be52435f67b91e53f15b8299cfe3d41347d86a32) by Zoltan K).
- fix: resolve all ansible-lint and yamllint violations ([ff13f13](https://github.com/kecsi-san/ansible-env-setup/commit/ff13f134291d4e36c874080413bd24d64b1c654d) by Zoltan K).
- fix: restore DOCUMENTATION block in profile_tasks callback override ([a466d22](https://github.com/kecsi-san/ansible-env-setup/commit/a466d225c42a9695ffbb7abe11495039266f6a6a) by Zoltan K).
- fix: use K3S_KUBECONFIG_MODE=644 to avoid become for kubeconfig copy ([ea0fdac](https://github.com/kecsi-san/ansible-env-setup/commit/ea0fdacd961d4d1ab3ad14eacb41b4adbbaefa00) by Zoltan K).
- fix: restore remote_src: true on k3s kubeconfig copy task ([3e33526](https://github.com/kecsi-san/ansible-env-setup/commit/3e33526956d1635ea51b9c41c7d7a8f439cfd0ba) by Zoltan K).
- fix: remote_src param remove from setup_k3s role ([ac3ac62](https://github.com/kecsi-san/ansible-env-setup/commit/ac3ac6204fc3b794937e27245f59dd48e6ae6bc2) by Zoltan K).
- fix: replace embedded Jinja templates in lookup with ~ concatenation ([fdc32ee](https://github.com/kecsi-san/ansible-env-setup/commit/fdc32ee0ade15d3707f6e6d7f0a7356e1b344ec8) by Zoltan K).
- fix: remove duplicate python_version var second occasion from setup_python-uv role ([3197a5c](https://github.com/kecsi-san/ansible-env-setup/commit/3197a5c673f7e584ac0cb2bbe8b3baa1813f3344) by Zoltan K).
- fix: hard code uv python venv version to 3.12 ([5fa6490](https://github.com/kecsi-san/ansible-env-setup/commit/5fa64908ada66b69416449749538bba302f4b6b0) by Zoltan K).
- fix: remove aspose-diagram packages — require jpype1 which needs g++-12 ([ab22c95](https://github.com/kecsi-san/ansible-env-setup/commit/ab22c95f03deba690b41dcc1c1e822cd4d27b9b4) by Zoltan K).
- fix: remove dot2mmd — not found in PyPI registry ([379ccf8](https://github.com/kecsi-san/ansible-env-setup/commit/379ccf88d8cca970488bdf3bd16da2f9d6c497d0) by Zoltan K).
- fix: move all inline comments to their own lines in .gitignore ([cecd5b8](https://github.com/kecsi-san/ansible-env-setup/commit/cecd5b8bcfb5189468eabd980c80da110f702f39) by Zoltan K).
- fix: remove diagraform — not found in PyPI registry ([01b4858](https://github.com/kecsi-san/ansible-env-setup/commit/01b485837f61c402ed6c51b6941c1d23fb75c542) by Zoltan K).
- fix: use lookup('env', 'HOME') for uv venv path ([594253a](https://github.com/kecsi-san/ansible-env-setup/commit/594253aba38f1c7d2341903b6626b2f670cdc6cf) by Zoltan K).
- fix: install mkdocs (not mkdocs-material) as uv tool ([60801d9](https://github.com/kecsi-san/ansible-env-setup/commit/60801d9bee5c5fdd3dd00e9f309e9758b3401342) by Zoltan K).
- fix: switch playbooks from roles: to import_role for correct tag filtering ([4076d92](https://github.com/kecsi-san/ansible-env-setup/commit/4076d922f9927af7f4e9a27180fba9a9056878c5) by Zoltan K).

<!-- insertion marker -->
