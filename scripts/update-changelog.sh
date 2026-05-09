#!/usr/bin/env bash
set -euo pipefail

git-changelog -o CHANGELOG.md

if ! git diff --quiet CHANGELOG.md; then
    git add CHANGELOG.md
    git commit --no-verify -m "docs: update CHANGELOG.md [skip ci]"
    echo "CHANGELOG.md updated."
fi
