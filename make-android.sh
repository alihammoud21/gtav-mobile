#!/bin/sh
set -eu
cd "$(dirname "$0")"
MODE="${1:-debug}"
case "$MODE" in debug|release|--native-only) ;; *) echo "Usage: $0 [debug|release|--native-only]" >&2; exit 2 ;; esac
: "${ANDROID_HOME:=${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
: "${ANDROID_NDK_HOME:=$ANDROID_HOME/ndk/28.2.13676358}"
export ANDROID_HOME ANDROID_NDK_HOME
case "$(uname -s)" in
    Darwin) NDK_HOST=darwin-x86_64 ;;
    Linux) NDK_HOST=linux-x86_64 ;;
    *) echo "Build Android on macOS or Linux (or use Android Studio/WSL)." >&2; exit 1 ;;
esac
NDK_BIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$NDK_HOST/bin"
[ -x "$NDK_BIN/aarch64-linux-android28-clang" ] || { echo "Install NDK 28.2.13676358 with sdkmanager, or set ANDROID_NDK_HOME." >&2; exit 1; }
export CC_aarch64_linux_android="$NDK_BIN/aarch64-linux-android28-clang"
export CXX_aarch64_linux_android="$NDK_BIN/aarch64-linux-android28-clang++"
export AR_aarch64_linux_android="$NDK_BIN/llvm-ar"
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$CC_aarch64_linux_android"
export CARGO_TARGET_AARCH64_LINUX_ANDROID_RUSTFLAGS="-C link-arg=-Wl,-z,max-page-size=16384"
if [ "$MODE" = --native-only ]; then
    cargo build --locked --release --target aarch64-linux-android --lib
    mkdir -p android/app/src/main/jniLibs/arm64-v8a
    cp target/aarch64-linux-android/release/libgtav_mobile.so android/app/src/main/jniLibs/arm64-v8a/
    exit 0
fi
if [ -z "${JAVA_HOME:-}" ] && [ -d /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ]; then
    export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
fi
TASK=assembleDebug
[ "$MODE" != release ] || TASK=assembleRelease
./android/gradlew -p android "$TASK"
mkdir -p build
if [ "$MODE" = release ]; then
    cp android/app/build/outputs/apk/release/app-release-unsigned.apk build/gtav-mobile-unsigned.apk
    echo "Built build/gtav-mobile-unsigned.apk (sign it with your release key before installing)."
else
    cp android/app/build/outputs/apk/debug/app-debug.apk build/gtav-mobile-debug.apk
    echo "Built build/gtav-mobile-debug.apk"
fi
