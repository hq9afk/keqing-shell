#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

quickshell -c keqing-shell kill >/dev/null 2>&1 || true
"$HERE/install.sh"
exec quickshell -c keqing-shell
