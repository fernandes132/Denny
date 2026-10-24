#!/bin/bash
# Compile the real CarPlay target. Approval/signing cannot be supplied by this script.
set -euo pipefail
LUMA_PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$LUMA_PROJECT_ROOT"
LUMA_CARPLAY_SDK="$(xcrun --sdk iphoneos --show-sdk-version)"
if [ "${LUMA_CARPLAY_SDK%%.*}" -lt 27 ]; then
  echo "CarPlay candidate requires iOS 27 SDK; found $LUMA_CARPLAY_SDK." >&2
  exit 1
fi
xcodebuild -version
xcodebuild -project Luma.xcodeproj -scheme Luma-CarPlay -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/CarPlaySimulator CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Luma.xcodeproj -scheme Luma-CarPlay -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build/CarPlayDevice CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build

LUMA_CARPLAY_APP="$LUMA_PROJECT_ROOT/build/CarPlayDevice/Build/Products/Release-iphoneos/Luma-CarPlay.app"
LUMA_CARPLAY_EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$LUMA_CARPLAY_APP/Info.plist")"
xcrun lipo "$LUMA_CARPLAY_APP/$LUMA_CARPLAY_EXECUTABLE" -verify_arch arm64
python3 scripts/verify_device_binary.py "$LUMA_CARPLAY_APP/$LUMA_CARPLAY_EXECUTABLE"

LUMA_CARPLAY_OUTPUT="$LUMA_PROJECT_ROOT/build/carplay"
LUMA_CARPLAY_STAGE="$(mktemp -d "$LUMA_PROJECT_ROOT/build/carplay-package.XXXXXX")"
trap 'rm -rf "$LUMA_CARPLAY_STAGE"' EXIT
mkdir -p "$LUMA_CARPLAY_OUTPUT" "$LUMA_CARPLAY_STAGE/Payload"
ditto "$LUMA_CARPLAY_APP" "$LUMA_CARPLAY_STAGE/Payload/Luma-CarPlay.app"
ditto -c -k --sequesterRsrc --keepParent "$LUMA_CARPLAY_STAGE/Payload" "$LUMA_CARPLAY_OUTPUT/Luma-CarPlay-unsigned.ipa"
cp Luma/CarPlay/CarPlay.entitlements "$LUMA_CARPLAY_OUTPUT/REQUESTED-CarPlay.entitlements"
python3 scripts/verify_carplay_package.py "$LUMA_CARPLAY_OUTPUT/Luma-CarPlay-unsigned.ipa"
{
  echo 'Luma CarPlay candidate — unsigned, not activated on a vehicle'
  echo 'Built: CarPlay scene target, simulator and physical iOS arm64, iOS 27 SDK.'
  echo 'Requested: com.apple.developer.carplay-video. This is not an Apple approval.'
  echo 'Signing: none; no approved entitlement or provisioning profile embedded.'
  echo 'Not directly installable. Personal sideloading does not grant CarPlay privileges.'
  echo 'YouTube playback over CarPlay is not validated. Native HLS test is separate.'
  echo 'Actual activation requires Apple-approved capability, correct signing and a supported car.'
  xcodebuild -version
  shasum -a 256 "$LUMA_CARPLAY_OUTPUT/Luma-CarPlay-unsigned.ipa"
} > "$LUMA_CARPLAY_OUTPUT/BUILD-INFO.txt"
