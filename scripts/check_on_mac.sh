#!/bin/bash
# Runs the real Apple SDK checks when this source is opened on a Mac.
set -euo pipefail
LUMA_PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$LUMA_PROJECT_ROOT"
if ! command -v xcodebuild >/dev/null || ! command -v xcrun >/dev/null; then
  echo "Xcode ontbreekt. Installeer en open Xcode eerst op je MacBook." >&2
  exit 1
fi
mkdir -p build
xcodebuild -project Luma.xcodeproj -scheme Luma -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO build

if [ -z "${LUMA_SIMULATOR_ID:-}" ]; then
  LUMA_SIMULATOR_ID="$(xcrun simctl list devices available --json | python3 -c '
import json,sys
devices=json.load(sys.stdin)["devices"]
choices=[]
for runtime,items in devices.items():
    if ".iOS-" not in runtime: continue
    version=tuple(int(x) for x in runtime.split(".iOS-")[-1].split("-"))
    if version < (17,): continue
    for item in items:
        if "iPhone" in item["name"] and item.get("isAvailable",True):
            choices.append((version,item["udid"]))
if not choices: sys.exit("Geen iPhone-simulator met iOS 17+ gevonden. Installeer die in Xcode Settings > Components.")
print(sorted(choices,reverse=True)[0][1])
')"
fi
xcodebuild -project Luma.xcodeproj -scheme Luma \
  -destination "platform=iOS Simulator,id=$LUMA_SIMULATOR_ID" \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO test

LUMA_SDK_MAJOR="$(xcrun --sdk iphonesimulator --show-sdk-version | cut -d. -f1)"
if [ "$LUMA_SDK_MAJOR" -ge 27 ]; then
  xcodebuild -project Luma.xcodeproj -scheme Luma-CarPlay -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData-CarPlay \
    CODE_SIGNING_ALLOWED=NO build
else
  echo "CarPlay SDK-build overgeslagen: daarvoor is iOS 27 SDK vereist."
fi
echo "Build en XCTest afgerond. Playback en CarPlay op echte hardware moeten afzonderlijk worden getest."
