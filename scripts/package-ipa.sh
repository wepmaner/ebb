#!/usr/bin/env bash
# Packs the unsigned Release build into an .ipa (zip with Payload/Ebb.app) for LiveContainer.
# Usage: scripts/package-ipa.sh <derivedDataPath> <out.ipa>
set -euo pipefail
DERIVED="$1"
OUT_DIR=$(cd "$(dirname "$2")" && pwd)
OUT="$OUT_DIR/$(basename "$2")"

APP=$(find "$DERIVED/Build/Products" -maxdepth 2 -type d -name "Ebb.app" -path "*Release-iphoneos*" | head -1)
if [ -z "$APP" ]; then
  echo "Ebb.app not found under $DERIVED/Build/Products" >&2
  exit 1
fi

TMP=$(mktemp -d)
mkdir -p "$TMP/Payload"
cp -R "$APP" "$TMP/Payload/"
rm -f "$OUT"
(cd "$TMP" && zip -qry "$OUT" Payload)
rm -rf "$TMP"
ls -la "$OUT"
