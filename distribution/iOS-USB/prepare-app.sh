#!/bin/bash
# Xcode runs this before its normal signing phase. The game is already compiled.
set -euo pipefail
[ "${PLATFORM_NAME:-}" = iphoneos ] || { echo 'error: Select a connected iPhone or iPad, not a simulator.' >&2; exit 1; }
: "${SRCROOT:?}" "${TARGET_TEMP_DIR:?}" "${TARGET_BUILD_DIR:?}" "${WRAPPER_NAME:?}" "${EXECUTABLE_PATH:?}"
cd "$SRCROOT/.."
shasum -a 256 -c "$SRCROOT/Game.sha256"
STAGE="$TARGET_TEMP_DIR/GTAVMobile-precompiled"
# This is an isolated, disposable directory owned by this build phase.
if [ -e "$STAGE" ]; then rm -rf "$STAGE"; fi
mkdir -p "$STAGE"
ditto -x -k GTAVMobile-ios.ipa "$STAGE"
APP_SOURCE="$STAGE/Payload/GTAVMobile.app"
[ -f "$APP_SOURCE/gtav-mobile" ] || { echo 'error: The IPA has no game executable.' >&2; exit 1; }
# Keep Xcode's generated bundle ID, Info.plist, and device provisioning profile.
# Xcode applies the selected Personal Team signature after this build phase.
rsync -a --exclude Info.plist --exclude embedded.mobileprovision --exclude _CodeSignature --exclude PkgInfo \
  "$APP_SOURCE/" "$TARGET_BUILD_DIR/$WRAPPER_NAME/"
chmod +x "$TARGET_BUILD_DIR/$EXECUTABLE_PATH"

# This declared build output makes Xcode's CodeSign task depend on every
# replacement of the precompiled executable, including incremental Run builds.
touch "$TARGET_BUILD_DIR/$EXECUTABLE_PATH"
printf '%s\n' "Prepared by build phase $$" > "$TARGET_BUILD_DIR/$WRAPPER_NAME/GTAVPrepared.txt"
