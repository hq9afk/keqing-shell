#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"

sudo rm -rf /etc/xdg/quickshell/keqing-shell
sudo rm -f /usr/bin/keqing-shell

# C++ plugins: derive the installed KeqingShell qml dir from the install manifest
manifest="$ROOT/build/install_manifest.txt"
if [[ -f "$manifest" ]]; then
    keqdir="$(grep -m1 -o '.*/KeqingShell' "$manifest" || true)"
    [[ -n "$keqdir" ]] && sudo rm -rf "$keqdir"
else
    echo "No $manifest; remove the installed KeqingShell qml dir manually" \
         "(e.g. /usr/lib/qt6/qml/KeqingShell)."
fi
