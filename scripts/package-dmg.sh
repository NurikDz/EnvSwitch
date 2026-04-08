#!/usr/bin/env bash
set -euo pipefail

# Signing: set CODESIGN_IDENTITY to the full string from:
#   security find-identity -v -p codesigning
# Example: export CODESIGN_IDENTITY='Developer ID Application: …'
# Unsigned DMG: SKIP_CODESIGN=1
# DMG window layout: run in Terminal.app, or SKIP_DMG_FINDER_LAYOUT=1

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# create-dmg does not delete rw.<pid>.*.dmg if it exits early (e.g. Finder AppleScript denied).
cleanup_rw_dmg_temp() {
  find "${ROOT}/build" -maxdepth 1 -name 'rw.*.dmg' -delete 2>/dev/null || true
}
trap cleanup_rw_dmg_temp EXIT

DERIVED="${ROOT}/build/DerivedData"
APP="${DERIVED}/Build/Products/Release/EnvSwitch.app"
ICON="${ROOT}/EnvSwitch/Assets.xcassets/AppIcon.appiconset/icon.icns"
ENTITLEMENTS="${ROOT}/scripts/EnvSwitch-distribution.entitlements"
STAGE="${ROOT}/build/dmg_stage"
BG="${ROOT}/build/dmg_background.png"
OUT="${ROOT}/build/EnvSwitch.dmg"
WIN_W=660
WIN_H=400
SKIP_CODESIGN="${SKIP_CODESIGN:-0}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-}"

if [[ "$SKIP_CODESIGN" == 1 ]]; then
  CODESIGN_IDENTITY=""
  echo "SKIP_CODESIGN=1: unsigned DMG." >&2
elif [[ -z "$CODESIGN_IDENTITY" ]]; then
  echo "Set CODESIGN_IDENTITY to an Apple signing identity from the keychain, or SKIP_CODESIGN=1." >&2
  echo "List identities: security find-identity -v -p codesigning" >&2
  exit 1
else
  echo "Signing with: ${CODESIGN_IDENTITY}" >&2
fi

echo "Building signed Release (Xcode + hardened runtime from project settings)…"
xcodebuild \
  -scheme EnvSwitch \
  -configuration Release \
  -project "${ROOT}/EnvSwitch.xcodeproj" \
  -derivedDataPath "${DERIVED}" \
  build \
  >/dev/null

echo "Rendering DMG background…"
mkdir -p "${ROOT}/build"
swiftc -O -framework AppKit "${ROOT}/scripts/RenderDMGBackground.swift" -o "${ROOT}/build/render_dmg_bg"
"${ROOT}/build/render_dmg_bg" "${ICON}" "${WIN_W}" "${WIN_H}" "${BG}"

rm -rf "${STAGE}"
mkdir -p "${STAGE}"
ditto "${APP}" "${STAGE}/EnvSwitch.app"

if [[ -n "$CODESIGN_IDENTITY" ]]; then
  echo "Signing EnvSwitch.app…"
  codesign --force \
    --sign "${CODESIGN_IDENTITY}" \
    --options runtime \
    --timestamp \
    --entitlements "${ENTITLEMENTS}" \
    "${STAGE}/EnvSwitch.app"
  codesign --verify --verbose=2 "${STAGE}/EnvSwitch.app"
fi

echo "Creating disk image…"
rm -f "${OUT}"

CREATE_DMG_OPTS=(
  --volname "EnvSwitch"
  --volicon "${ICON}"
  --background "${BG}"
  --window-size "${WIN_W}" "${WIN_H}"
  --icon-size 112
  --icon "EnvSwitch.app" 176 205
  --hide-extension "EnvSwitch.app"
  --app-drop-link 484 205
  --no-internet-enable
)
if [[ -n "$CODESIGN_IDENTITY" ]]; then
  CREATE_DMG_OPTS+=( --codesign "${CODESIGN_IDENTITY}" )
fi

if [[ "${SKIP_DMG_FINDER_LAYOUT:-}" == 1 ]]; then
  echo "(SKIP_DMG_FINDER_LAYOUT=1: skipping Finder AppleScript; layout/background may be plain.)"
  CREATE_DMG_OPTS+=( --skip-jenkins )
fi

create-dmg "${CREATE_DMG_OPTS[@]}" "${OUT}" "${STAGE}"

echo "Done: ${OUT}"
echo "If the app icon looks wrong in Finder, eject every EnvSwitch volume, then open this disk image (stale mounts can show an older .app)." >&2
