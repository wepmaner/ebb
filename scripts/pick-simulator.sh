#!/usr/bin/env bash
# Prints the UDID of the newest available iPhone simulator on this machine.
set -euo pipefail
xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
candidates = []
for runtime, devs in devices.items():
    if "iOS" not in runtime:
        continue
    for dev in devs:
        if dev.get("isAvailable") and dev["name"].startswith("iPhone"):
            candidates.append((runtime, dev["name"], dev["udid"]))
if not candidates:
    sys.exit("no available iPhone simulator")
candidates.sort()
print(candidates[-1][2])
'
