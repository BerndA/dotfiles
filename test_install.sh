#!/bin/bash
set -euo pipefail
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER="dotfiles-test"

main() {
  echo "Install test - requires podman"
  echo ""
  [ -n "${CI:-}" ] && echo "CI env detected, skipping container test" && exit 0
  command -v podman >/dev/null || (echo "podman not installed" && exit 1)
  podman build -t "$CONTAINER" -f "$SCRIPT/Containerfile" . 2>&1 | tail -2
  podman run --rm -v "$SCRIPT:/install:ro" -u "$(id -u):$(id -g)" "$CONTAINER" \
    /bin/bash -c '/install/install.sh 2>&1'
}
main
