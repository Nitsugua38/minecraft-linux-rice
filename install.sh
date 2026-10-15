#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODULES=(plymouth greeter)

ONLY=""
ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --only) ONLY="$2"; shift 2 ;;
        *) ARGS+=("$1"); shift ;;
    esac
done

for m in "${MODULES[@]}"; do
    [[ -n "$ONLY" && "$ONLY" != "$m" ]] && continue
    if [[ -f "$HERE/$m/installer.sh" ]]; then
        echo "=== Module: $m ==="
        bash "$HERE/$m/installer.sh" "${ARGS[@]}"
    fi
done
