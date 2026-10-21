#!/usr/bin/env bash
# Exports every attachment (our screenshots) from an .xcresult bundle into a folder.
# Usage: scripts/export-screenshots.sh <path.xcresult> <outdir>
set -euo pipefail
XCRESULT="$1"
OUT="$2"
mkdir -p "$OUT"
xcrun xcresulttool export attachments --path "$XCRESULT" --output-path "$OUT"
# Rename files by their attachment names when the manifest is present (Xcode 16+).
if [ -f "$OUT/manifest.json" ]; then
  python3 - "$OUT" <<'PY'
import json, os, sys
out = sys.argv[1]
manifest = json.load(open(os.path.join(out, "manifest.json")))
for test in manifest:
    for att in test.get("attachments", []):
        src = os.path.join(out, att["exportedFileName"])
        name = att.get("suggestedHumanReadableName") or att["exportedFileName"]
        ext = os.path.splitext(att["exportedFileName"])[1] or ".png"
        dst = os.path.join(out, name if name.endswith(ext) else name + ext)
        if os.path.exists(src) and src != dst:
            os.replace(src, dst)
PY
fi
ls -la "$OUT"
