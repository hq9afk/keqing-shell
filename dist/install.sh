#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"

# C++ plugins
cmake -B "$ROOT/build" -DCMAKE_INSTALL_PREFIX=/usr "$ROOT/plugins"
cmake --build "$ROOT/build"
sudo cmake --install "$ROOT/build"

# Shell config (real copy, not symlink)
sudo rm -rf /etc/xdg/quickshell/keqing-shell
sudo mkdir -p /etc/xdg/quickshell
sudo cp -r "$ROOT/src" /etc/xdg/quickshell/keqing-shell

# Manager scripts (install unlinks any existing symlink first)
for bin in "$ROOT/bin/"*; do
    sudo install -m755 "$bin" "/usr/bin/${bin##*/}"
done
