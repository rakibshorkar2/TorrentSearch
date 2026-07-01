#!/bin/bash
# Build C++ torrent engine for iOS
# Run from project root: bash native/build_ios.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/native/build/ios"
OUTPUT_DIR="$PROJECT_ROOT/ios/Runner"

mkdir -p "$BUILD_DIR"

# Build for iOS device (arm64)
echo "Building torrent_engine for iOS arm64..."
cmake -S "$PROJECT_ROOT/native/torrent_engine" \
      -B "$BUILD_DIR" \
      -G Xcode \
      -DCMAKE_SYSTEM_NAME=iOS \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
      -DCMAKE_OSX_ARCHITECTURES=arm64 \
      -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO \
      -DIOS=ON

cmake --build "$BUILD_DIR" --config Release

# Copy library to iOS Runner directory
cp "$BUILD_DIR/Release/libtorrent_engine.a" "$OUTPUT_DIR/"
echo "Library copied to $OUTPUT_DIR/libtorrent_engine.a"
echo "Done!"
