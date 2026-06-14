#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ICONSET="$ROOT/AppIcon.iconset"

swift "$ROOT/generate-icons.swift" "$ROOT/output"

mkdir -p "$ICONSET"
cp "$ROOT/output/icon-16.png"   "$ICONSET/icon_16x16.png"
cp "$ROOT/output/icon-32.png"   "$ICONSET/icon_16x16@2x.png"
cp "$ROOT/output/icon-32.png"   "$ICONSET/icon_32x32.png"
cp "$ROOT/output/icon-64.png"   "$ICONSET/icon_32x32@2x.png"
cp "$ROOT/output/icon-128.png"  "$ICONSET/icon_128x128.png"
cp "$ROOT/output/icon-256.png"  "$ICONSET/icon_128x128@2x.png"
cp "$ROOT/output/icon-256.png"  "$ICONSET/icon_256x256.png"
cp "$ROOT/output/icon-512.png"  "$ICONSET/icon_256x256@2x.png"
cp "$ROOT/output/icon-512.png"  "$ICONSET/icon_512x512.png"
cp "$ROOT/output/icon-1024.png" "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o "$ROOT/output/AppIcon.icns"
rm -rf "$ICONSET"

echo "Generated AppIcon.icns"
