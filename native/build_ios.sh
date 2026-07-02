#!/bin/bash
# Build libtorrent FFI wrapper for iOS
# Run from project root: bash native/build_ios.sh
#
# Prerequisites:
#   1. macOS with Xcode 15+
#   2. Homebrew: brew install cmake ninja
#   3. libtorrent source in native/libtorrent_ffi/libtorrent/
#      (git submodule: git submodule add https://github.com/arvidn/libtorrent native/libtorrent_ffi/libtorrent)

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/native/build/ios"
OUTPUT_DIR="$PROJECT_ROOT/ios/Runner"
LIBTORRENT_SRC="$PROJECT_ROOT/native/libtorrent_ffi/libtorrent"
FFI_SRC="$PROJECT_ROOT/native/libtorrent_ffi"

mkdir -p "$BUILD_DIR"

if [ ! -d "$LIBTORRENT_SRC" ]; then
  echo "Error: libtorrent source not found at $LIBTORRENT_SRC"
  echo "Run: git submodule add https://github.com/arvidn/libtorrent $LIBTORRENT_SRC"
  exit 1
fi

echo "Building libtorrent FFI wrapper for iOS arm64..."
cmake -S "$FFI_SRC" \
      -B "$BUILD_DIR" \
      -G Xcode \
      -DCMAKE_SYSTEM_NAME=iOS \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
      -DCMAKE_OSX_ARCHITECTURES=arm64 \
      -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO \
      -DIOS=ON \
      -DBUILD_SHARED_LIBS=OFF \
      -Dtorrent-bindings=OFF \
      -Dtorrent-python-bindings=OFF \
      -Dtorrent-examples=OFF \
      -Dtorrent-tests=OFF \
      -Dtorrent-tools=OFF

cmake --build "$BUILD_DIR" --config Release

cp "$BUILD_DIR/Release/libtorrent_ffi.a" "$OUTPUT_DIR/"
echo "Library copied to $OUTPUT_DIR/libtorrent_ffi.a"
echo ""
echo "Next step: Update ios/Runner/Release.xcconfig to link libtorrent_ffi.a"
echo "  OTHER_LDFLAGS=\$(inherited) -L\"\$(PROJECT_DIR)/Runner\" -ltorrent_ffi"
echo "Done!"
