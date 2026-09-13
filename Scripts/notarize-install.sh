#!/bin/zsh
# Build → Developer ID sign (hardened runtime) → notarize → staple → install.
# macOS 26 requires input methods to be NOTARIZED to register as input sources.
#
# One-time setup (run yourself, interactive, so the secret never passes through
# the agent). First create an app-specific password at appleid.apple.com
# (Sign-In and Security → App-Specific Passwords), then:
#   xcrun notarytool store-credentials VTXNotary \
#         --apple-id <your-apple-id-email> --team-id CT94G6J3TH
#   (paste the app-specific password when prompted)
set -e
cd "$(dirname "$0")/.."

SIGN_ID="Developer ID Application: Khanh Nguyen (CT94G6J3TH)"
PROFILE="VTXNotary"
DEST="$HOME/Library/Input Methods/VTX.app"
SCRATCH="${TMPDIR:-/tmp}/vtx-notarize"

echo "→ building"
xcodegen generate >/dev/null 2>&1 || true
# Explicit derivedDataPath: multiple stale DerivedData dirs made the old
# `ls | head -1` pick an OUTDATED build (shipped old icons/name once). Build
# and install from ONE deterministic location.
DERIVED="${TMPDIR:-/tmp}/vtx-derived"
xcodebuild -project VietTelex.xcodeproj -scheme VietTelex \
           -configuration Release -destination 'platform=macOS' \
           -derivedDataPath "$DERIVED" \
           build | grep -E "BUILD" || true
APP="$DERIVED/Build/Products/Release/VTX.app"
[ -d "$APP" ] || { echo "build product not found: $APP"; exit 1; }

echo "→ cleaning stray legacy code seal + Developer ID sign + hardened runtime"
# xcodebuild leaves a legacy top-level Contents/CodeResources that no valid app
# (Apple's own IMEs, normal .apps) has. Strip it and the existing seal,
# then sign fresh so the bundle matches a clean modern signature.
rm -f "$APP/Contents/CodeResources"
codesign --remove-signature "$APP" 2>/dev/null || true
codesign --force --options runtime --timestamp \
         --entitlements App/Resources/VietTelex.entitlements \
         --sign "$SIGN_ID" "$APP"
if [ -f "$APP/Contents/CodeResources" ]; then
  echo "  WARNING: stray Contents/CodeResources reappeared after signing"; fi

echo "→ zipping + submitting to Apple notary (waits for result)"
mkdir -p "$SCRATCH"
ZIP="$SCRATCH/VTX.zip"
/usr/bin/ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait

echo "→ stapling the ticket"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"

echo "→ installing to $DEST"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
pkill -x VTX 2>/dev/null || true
rm -rf "$DEST"
/usr/bin/ditto "$APP" "$DEST"
"$LSREGISTER" -f "$DEST"
# The build copy in $DERIVED is registered too, under our bundle id. A registered
# stray copy has not been shown to break anything on its own (2026-09-13: four
# registrations, VTX kept working), but a second VTX PROCESS sharing the connection
# name did knock VTX out of the menu bar (2026-08-15) — so keep exactly one.
# Unregister BEFORE anything deletes the directory: removing a bundle does not remove
# its record, and `mdfind` can't see $TMPDIR. See docs/MACOS_IME_NOTES.md.
"$LSREGISTER" -u "$APP" 2>/dev/null || true
registered=$("$LSREGISTER" -dump 2>/dev/null | grep -E '^path:.*/VTX\.app \(0x')
if [ "$(printf '%s\n' "$registered" | grep -c .)" -ne 1 ]; then
  echo "  WARNING: LaunchServices has more than one VTX.app registered (expected exactly 1)."
  echo "  Unregister every path below except ~/Library/Input Methods with: $LSREGISTER -u <path>"
  printf '%s\n' "$registered" | sed 's/^/    /'
fi
spctl -a -t exec -vv "$DEST" 2>&1 | head -2
# DO NOT blanket-reset the Accessibility grant here (it used to, forcing a
# re-grant on EVERY install). The designated requirement is identity-based
# (identifier + team), so a same-identity re-sign normally keeps the grant
# valid. When macOS does wedge the grant anyway, the app now DETECTS it
# (trusted but tap-create refused) and walks the user through remove+re-add
# via the menu status line — see TerminalTapController.trustLooksStale.
pkill -x VTX 2>/dev/null || true

echo "Done. Log out / log in ONCE (first install only), then add it: Keyboard → Input Sources → + → Vietnamese → VTX."
echo "If Terminal/Chromium typing stops after this install, the IME menu will show"
echo "'Quyền trợ năng bị kẹt' with one-click repair instructions."
