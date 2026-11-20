#!/usr/bin/env bash
# Render social-src/card.html (1600x900, apple-dark) to assets/social-card.jpg (2400x1260 class asset). Needs Google Chrome + sips.
set -euo pipefail
H="$(cd "$(dirname "$0")" && pwd)"; CH="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
"$CH" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1.5 --window-size=1600,840 --screenshot="$T/c.png" "file://$H/card.html" >/dev/null 2>&1
sips -s format jpeg -s formatOptions 90 "$T/c.png" --out "$H/../assets/social-card.jpg" >/dev/null
