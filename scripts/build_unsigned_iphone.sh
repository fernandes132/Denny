#!/bin/bash
# Builds a device binary; this intentionally does not pretend to sign/install it.
set -euo pipefail
LUMA_PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$LUMA_PROJECT_ROOT"
if ! command -v xcodebuild >/dev/null || ! command -v xcrun >/dev/null; then
  echo "Deze stap vereist macOS met Xcode, lokaal of via een cloudrunner." >&2
  exit 1
fi

xcodebuild -project Luma.xcodeproj -scheme Luma -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build/DeviceDerivedData \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build

LUMA_APP_PATH="$LUMA_PROJECT_ROOT/build/DeviceDerivedData/Build/Products/Release-iphoneos/Luma.app"
if [ ! -f "$LUMA_APP_PATH/Luma" ] || [ ! -f "$LUMA_APP_PATH/Info.plist" ]; then
  echo "De verwachte iPhone-app ontbreekt; geen IPA gemaakt." >&2
  exit 1
fi
# Inspect the actual device binary before packaging; a simulator app is not an iPhone build.
xcrun lipo -verify_arch arm64 "$LUMA_APP_PATH/Luma"
python3 scripts/verify_device_binary.py "$LUMA_APP_PATH/Luma"

LUMA_IPHONE_OUTPUT="$LUMA_PROJECT_ROOT/build/iphone"
LUMA_PACKAGE_STAGE="$(mktemp -d "$LUMA_PROJECT_ROOT/build/iphone-package.XXXXXX")"
trap 'rm -rf "$LUMA_PACKAGE_STAGE"' EXIT
mkdir -p "$LUMA_IPHONE_OUTPUT" "$LUMA_PACKAGE_STAGE/Payload"
ditto "$LUMA_APP_PATH" "$LUMA_PACKAGE_STAGE/Payload/Luma.app"
ditto -c -k --sequesterRsrc --keepParent "$LUMA_PACKAGE_STAGE/Payload" "$LUMA_IPHONE_OUTPUT/Luma-unsigned.ipa"

python3 - "$LUMA_IPHONE_OUTPUT/Luma-unsigned.ipa" <<'PY'
import sys,zipfile
with zipfile.ZipFile(sys.argv[1]) as archive:
    required={'Payload/Luma.app/Luma','Payload/Luma.app/Info.plist'}
    if not required.issubset(archive.namelist()):
        raise SystemExit('IPA heeft geen geldige Payload/Luma.app-structuur.')
    if archive.testzip() is not None:
        raise SystemExit('IPA-integriteitscontrole mislukt.')
PY

{
  echo 'Luma — unsigned iPhone build'
  echo 'Platform: physical iOS device (arm64), not iOS Simulator.'
  echo 'Signing: none. This file is NOT directly installable on an iPhone.'
  echo 'Install: requires valid personal/development signing on a computer.'
  echo 'CarPlay: this is the regular Luma target; no restricted CarPlay entitlement.'
  echo 'YouTube and CarPlay hardware playback remain separate device tests.'
  xcodebuild -version
  shasum -a 256 "$LUMA_IPHONE_OUTPUT/Luma-unsigned.ipa"
} > "$LUMA_IPHONE_OUTPUT/BUILD-INFO.txt"
echo "Ongetekende iPhone-build: $LUMA_IPHONE_OUTPUT/Luma-unsigned.ipa"
