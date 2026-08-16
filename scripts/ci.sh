#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scripts/bootstrap.sh
scripts/repo-guards.sh
simulator_id="${IOS_SIMULATOR_ID:-$(python3 - <<'PY'
import json
import subprocess

runtimes = json.loads(subprocess.check_output(
    ["xcrun", "simctl", "list", "runtimes", "-j"], text=True
))["runtimes"]
devices = json.loads(subprocess.check_output(
    ["xcrun", "simctl", "list", "devices", "available", "-j"], text=True
))["devices"]
available = [runtime for runtime in runtimes if runtime.get("isAvailable")]
stable = [runtime for runtime in available if runtime["buildversion"][-1].isdigit()]
candidates = stable or available
candidates.sort(key=lambda runtime: tuple(map(int, runtime["version"].split("."))), reverse=True)
for runtime in candidates:
    for device in devices.get(runtime["identifier"], []):
        device_type = device.get("deviceTypeIdentifier", "")
        if device.get("isAvailable") and (
            device_type.startswith("com.apple.CoreSimulator.SimDeviceType.iPhone")
            or device["name"].startswith("iPhone")
        ):
            print(device["udid"])
            raise SystemExit
raise SystemExit("no available iPhone simulator")
PY
)}"
destination="platform=iOS Simulator,id=$simulator_id"
xcodebuild -project Soundscape.xcodeproj -scheme Soundscape -destination "$destination" clean build
xcodebuild -project Soundscape.xcodeproj -scheme Soundscape -destination "$destination" test
