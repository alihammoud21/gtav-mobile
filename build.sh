#!/bin/bash
# muguet - build.sh
# Constantin Clerc (c22dev) - 0.1

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo /)"
cd "$HERE"

TOOLCHAIN=1.98.1
OUT="$HOME/Downloads/gtavMobileOutput"
SAVED=build/.choices

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
fail() { printf '\n\033[31m%s\033[0m\n' "$*" >&2; exit 1; }
ask() {
  local answer
  read -r -e -p "$1 [$2]: " answer || exit 1
  answer="$(printf '%s' "$answer" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  REPLY="${answer:-$2}"
}
pick() {
  local prompt="$1"; shift
  bold "$prompt"
  PS3="Choose 1-$#: "
  select choice in "$@"; do
    [ -n "${choice:-}" ] && return
    echo "Type a number between 1 and $#."
  done
  exit 1
}
clean_path() {
  local p="$1"
  p="${p#\'}"; p="${p%\'}"; p="${p#\"}"; p="${p%\"}"
  p="${p//\\ / }"
  p="${p/#\~/$HOME}"
  printf '%s' "$p"
}
game_zip() { [ -f "$1" ] && unzip -Z1 "$1" 2>/dev/null | grep -E '(^|/)b/[^/]+/game\.wasm$' >/dev/null; }
xcode_teams() {
  defaults export com.apple.dt.Xcode - 2>/dev/null | /usr/bin/python3 -I -c '
import plistlib, sys
try: d = plistlib.loads(sys.stdin.buffer.read())
except Exception: sys.exit()
seen = set()
for teams in d.get("IDEProvisioningTeamByIdentifier", {}).values():
    for t in teams:
        if t.get("teamID") and t["teamID"] not in seen:
            seen.add(t["teamID"])
            print("%s\t%d\t%s" % (t["teamID"], bool(t.get("isFreeProvisioningTeam")), t.get("teamName", t["teamID"])))
' || true
}
run() {
  mkdir -p build
  if "$@" 2>&1 | tee build/build.log; then return; fi
  explain
}
explain() {
  local log=build/build.log hint=""
  if grep -E "No Account for Team|No signing certificate|No profiles for|requires a provisioning profile" "$log" >/dev/null; then
    hint="Xcode couldn't sign the app. Open Xcode > Settings > Accounts, check you're signed in with your Apple ID, then run this again."
  elif grep -E "maximum number of apps|App ID limit" "$log" >/dev/null; then
    hint="Free Apple IDs can only have a few sideloaded apps at once. Delete one from your device, wait a bit, then run this again."
  elif grep -E "Failed to register bundle identifier|is not available|cannot be registered" "$log" >/dev/null; then
    hint="That app identifier is already taken. Run this again with your own one, like: BUNDLE_ID=com.yourname.gtavmobile ./build.sh"
  elif grep -E "No space left on device" "$log" >/dev/null; then
    hint="Your Mac ran out of disk space. Free up at least 15 GB, then run this again."
  elif grep -iE "device is locked|passcode" "$log" >/dev/null; then
    hint="Your device is locked. Unlock it, keep it unlocked, then run this again."
  elif grep -E "Developer Mode" "$log" >/dev/null; then
    hint="Turn on Settings > Privacy & Security > Developer Mode on your device, restart it, then run this again."
  elif grep -E "untrusted|not trusted|ApplicationVerificationFailed" "$log" >/dev/null; then
    hint="Unlock your device and tap Trust when it asks to trust this Mac, then run this again."
  fi
  printf '\n\033[31mThe build failed.\033[0m\n'
  if [ -n "$hint" ]; then echo "$hint"; else echo "Last lines of the log:"; tail -15 "$log"; fi
  echo "Full log: $PWD/$log"
  exit 1
}
remember() { mkdir -p build; echo "LAST_ZIP=$(printf '%q' "$ZIP")" > "$SAVED"; }

[ "$(uname -s)" = Darwin ] || fail "GTAVMobile builds on macOS only."
[ "$(uname -m)" = arm64 ] || fail "GTAVMobile needs an Apple Silicon Mac (M1 or newer)."

bold "Checking Xcode"
if ! xcodebuild -version >/dev/null 2>&1; then
  XCODE="$(ls -d /Applications/Xcode*.app 2>/dev/null | head -1)"
  [ -n "$XCODE" ] || fail "Install Xcode from the App Store (Xcode 26 or later), open it once, then run this again."
  echo "Xcode is installed but not selected. Selecting it (asks for your Mac password):"
  sudo xcode-select -s "$XCODE/Contents/Developer"
fi
XCODE_MAJOR="$(xcodebuild -version | awk '/^Xcode/ {split($2, v, "."); print v[1]}')"
[ "${XCODE_MAJOR:-0}" -ge 26 ] || fail "Xcode $XCODE_MAJOR is too old: update Xcode to 26 or later from the App Store."
if ! xcodebuild -license check >/dev/null 2>&1; then
  echo "Accepting the Xcode license (asks for your Mac password):"
  sudo xcodebuild -license accept
fi
xcodebuild -version | head -1

pick "What do you want to build?" "GTAVMobile for this Mac" "GTAVMobile for iPhone / iPad"
PLATFORM="$REPLY"

bold "Checking Homebrew"
if ! command -v brew >/dev/null; then
  [ -x /opt/homebrew/bin/brew ] || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
brew --version | head -1
if [ "$PLATFORM" = 2 ]; then
  for tool in xcodegen:xcodegen wasm-opt:binaryen; do
    command -v "${tool%%:*}" >/dev/null || { bold "Installing ${tool##*:}"; brew install "${tool##*:}"; }
  done
fi

bold "Checking Rust"
export PATH="/opt/homebrew/opt/rustup/bin:$HOME/.cargo/bin:$PATH"
if ! command -v rustup >/dev/null; then
  brew install rustup
  hash -r
fi
rustup toolchain list | grep '^stable' >/dev/null || rustup toolchain install stable --profile minimal
rustup default >/dev/null 2>&1 || rustup default stable
cargo --version

if [ "$PLATFORM" = 1 ]; then
  bold "Downloading Rust dependencies"
  cargo fetch --locked
  bold "Building GTAVMobile (a few minutes the first time)"
  run ./make-app.sh
  mkdir -p "$OUT"
  rm -rf "$OUT/GTAVMobile.app"
  ditto build/GTAVMobile.app "$OUT/GTAVMobile.app"
  bold "Done: $OUT/GTAVMobile.app"
  echo "Showing it in Finder: open it, then import your game .zip."
  open -R "$OUT/GTAVMobile.app"
  exit 0
fi

bold "Preparing the iOS toolchain"
rustup toolchain list | grep "^$TOOLCHAIN" >/dev/null || rustup toolchain install "$TOOLCHAIN" --profile minimal
rustup target list --toolchain "$TOOLCHAIN" --installed | grep '^aarch64-apple-ios$' >/dev/null || rustup target add aarch64-apple-ios --toolchain "$TOOLCHAIN"
if ! xcodebuild -showsdks 2>/dev/null | grep iphoneos >/dev/null; then
  echo "Downloading the iOS platform for Xcode (a few GB):"
  xcodebuild -downloadPlatform iOS
fi
bold "Downloading Rust dependencies"
cargo fetch --locked

LAST_ZIP=""
[ -f "$SAVED" ] && . "$SAVED"
game_zip "$LAST_ZIP" || LAST_ZIP=""

bold "Your game data"
echo "The .zip with data/ and b/<build>/game.wasm inside. Drag it into this window, then press Enter."
while :; do
  ask "Game .zip" "$LAST_ZIP"
  ZIP="$(clean_path "$REPLY")"
  if [ -z "$ZIP" ]; then echo "Drag your game .zip into this window, then press Enter."
  elif [ ! -f "$ZIP" ]; then echo "No file at: $ZIP"
  elif ! game_zip "$ZIP"; then echo "That .zip has no b/<build>/game.wasm inside."
  else break
  fi
done
remember

pick "How do you want to install it?" \
  "Make an .ipa (install it with AltStore)" \
  "Install it on my iPhone / iPad now (plugged into this Mac)"
OUTPUT="$REPLY"

FREE=0
TEAM="${TEAM:-}"
if [ "$OUTPUT" = 2 ] && [ -z "$TEAM" ]; then
  bold "Signing"
  while :; do
    TEAMS="$(xcode_teams)"
    [ -n "$TEAMS" ] && break
    echo "Xcode needs your Apple ID to sign the app (a free one works)."
    echo "Opening Xcode: go to Settings > Accounts, click +, choose Apple ID and sign in."
    open -a Xcode
    read -r -p "Press Enter once you're signed in. " _ || exit 1
  done
  if [ "$(printf '%s\n' "$TEAMS" | wc -l)" -gt 1 ]; then
    NAMES=()
    while IFS=$'\t' read -r _ free name; do
      NAMES+=("$name$([ "$free" = 1 ] && echo " (free)")")
    done <<< "$TEAMS"
    pick "Which account should sign GTAVMobile?" "${NAMES[@]}"
    LINE="$(printf '%s\n' "$TEAMS" | sed -n "${REPLY}p")"
  else
    LINE="$TEAMS"
  fi
  TEAM="$(printf '%s' "$LINE" | cut -f1)"
  FREE="$(printf '%s' "$LINE" | cut -f2)"
  echo "Signing with $(printf '%s' "$LINE" | cut -f3)$([ "$FREE" = 1 ] && echo "'s free account" || echo "'s developer account")."
fi

BUNDLE="${BUNDLE_ID:-com.$(id -un | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]').gtavmobile}"

FREE_KB="$(df -k . | awk 'NR==2 {print $4}')"
[ "$FREE_KB" -gt $((15 * 1024 * 1024)) ] || echo "Warning: less than 15 GB free on this disk, the build may run out of space."

if [ "$OUTPUT" = 2 ]; then
  while ! xcrun devicectl list devices 2>/dev/null | grep -E 'iPhone|iPad' | grep -E 'available \(paired\)|connected' >/dev/null; do
    echo
    echo "No iPhone / iPad found. Plug it in with a cable, unlock it, tap Trust,"
    echo "and turn on Settings > Privacy & Security > Developer Mode."
    read -r -p "Press Enter to look again. " _ || exit 1
  done
fi

bold "Building GTAVMobile for iOS (10-30 minutes the first time)"
if [ "$OUTPUT" = 1 ]; then
  BUNDLE_ID="$BUNDLE" run ./make-ios.sh "$ZIP" --ipa
  mkdir -p "$OUT"
  cp build/GTAVMobile.ipa "$OUT/GTAVMobile.ipa"
  bold "Done: $OUT/GTAVMobile.ipa"
  echo "Showing it in Finder: open it with AltStore."
  open -R "$OUT/GTAVMobile.ipa"
else
  TEAM="$TEAM" BUNDLE_ID="$BUNDLE" FREE="$FREE" run ./make-ios.sh "$ZIP" --install
  bold "Done: GTAVMobile is on your device"
  echo "If it says \"Untrusted Developer\": Settings > General > VPN & Device Management, tap your account, Trust."
fi
