# TorrentFlow

A premium iOS-native BitTorrent download manager with Seedr cloud integration, built with Flutter, C++, and Swift.

## Features

### Tab: Search
- Search multiple torrent indexers via a unified API with pagination
- Rich result cards with seeders, leechers, size, and health color indicator
- Tap to view details — open magnet links, copy info hash, or send to Downloads
- Search history persisted via Hive with quick-tap re-search
- Glass-morphism card design with frosted backgrounds

### Tab: Downloads
- Concurrent HTTP downloads via `Dio` with pause / resume / cancel per task
- Real-time progress bar, download speed, ETA, and file size display
- Add downloads from URL, magnet link, or imported `.torrent` files
- Background downloads via native iOS `URLSession` for Seedr/HTTP sources
- Active torrent keep-alive with 30s timer + silent audio playback (iOS limitation)
- Local push notifications on download completion
- WiFi-only enforcement option in Settings
- Swipe-to-delete with confirmation action sheet

### Tab: Seedr
- OAuth login with credentials stored securely in iOS Keychain
- Browse Seedr.cc folder tree — folders, files, and torrents
- Search your Seedr library for files and torrents
- Add magnet links directly to your Seedr account for cloud downloading
- Download files from Seedr to device with background URLSession
- Logout clears Keychain-stored credentials

### Tab: Settings
- Dark Mode toggle with instant theme switching (Cupertino)
- Follow System Theme option (auto-switch with iOS appearance)
- Auto-Import Magnets — toggle automatic magnet link detection
- Download Settings: WiFi-only toggle, max concurrent downloads, save directory
- Clear search history, cache, and downloaded files
- App info: version, build number, licenses

### C++ Native Engine
- **SHA-1 hashing** — FIPS-compliant implementation for piece verification
- **Bencode parser** — Full torrent metadata parsing (piece hashes, trackers, lengths)
- **Magnet URI parser** — Extract info hashes, trackers, display names
- **Piece manager** — 16KB block-level piece assembly and verification
- **Bandwidth shaper** — Configurable upload/download rate limits
- **Torrent health calculator** — Composite score from seeder/leecher ratios

### iOS Native Service (Swift)
- `FlutterMethodChannel` bridge for all native features
- Background `URLSession` with delegate-based completion handling
- Local notifications via `UserNotifications` framework
- Keychain storage via Security framework APIs
- Network path monitoring (`NWPathMonitor`) for connectivity status
- Device info (model name, thermal state, storage capacity)

### UI/UX
- 100% Cupertino widgets — zero Material Design dependencies
- Liquid Glass aesthetic with frosted backgrounds and blur effects
- Dark/light mode synced with system appearance
- iPhone 15 Pro optimized with 120Hz ProMotion support
- Portrait-only layout with OLED-friendly colors

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Flutter Dart Layer (lib/)                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │  Search   │ │Downloads │ │   Seedr  │ │ Settings │  │
│  │  Screen   │ │  Screen  │ │  Screen  │ │  Screen  │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘  │
│       │            │            │             │         │
│  ┌────┴────────────┴────────────┴─────────────┴────┐   │
│  │           Riverpod State Management             │   │
│  └────┬────────────┬────────────┬─────────────┬────┘   │
│       │            │            │             │         │
│  ┌────┴────┐ ┌─────┴────┐ ┌────┴─────┐ ┌─────┴────┐   │
│  │ Search │ │ Download │ │  Seedr   │ │  Native  │   │
│  │Service │ │ Service  │ │ Service  │ │ Service  │   │
│  └────────┘ └──────────┘ └──────────┘ └────┬─────┘   │
└──────────────────────────────────────────────┼─────────┘
                                               │
        MethodChannel (com.torrentflow/native) │
                                               │
┌──────────────────────────────────────────────┼─────────┐
│  iOS Native Layer (Swift/ObjC)              │         │
│  ┌──────────────────────────────────────────┴──────┐  │
│  │        TorrentFlowNativeService                  │  │
│  │  ┌────────┐ ┌──────────┐ ┌──────┐ ┌──────────┐ │  │
│  │  │URLSess.│ │ Keychain │ │Notif.│ │Network   │ │  │
│  │  │Downlds │ │  Store   │ │Center│ │Monitor   │ │  │
│  │  └────────┘ └──────────┘ └──────┘ └──────────┘ │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                                               │
                                        FFI (dart:ffi)
                                               │
┌──────────────────────────────────────────────┼─────────┐
│  C++ Engine (native/torrent_engine)          │         │
│  ┌────────┐ ┌──────────┐ ┌────────┐ ┌──────┐ │         │
│  │SHA-1   │ │ Bencode  │ │Magnet  │ │Piece │ │         │
│  │Hasher  │ │ Parser   │ │Parser  │ │Mgr   │ │         │
│  └────────┘ └──────────┘ └────────┘ └──────┘ │         │
└─────────────────────────────────────────────────────────┘
```

## Project Structure

```
lib/
  main.dart                          # App entry point + ProviderScope
  app.dart                          # Main CupertinoApp + tab shell
  core/
    constants/app_constants.dart     # API URLs, timeouts, configs
    extensions/                      # Dart extension methods
    native/
      native_bindings.dart          # FFI bindings for C++ engine
      native_service.dart           # MethodChannel bridge to Swift
    theme/
      app_theme.dart                # Color palette, typography, shadows
      cupertino_theme.dart          # Light/dark CupertinoThemeData
    widgets/
      glass_card.dart               # Liquid Glass effect widget
  features/
    downloads/                      # Download list UI + providers
    files/                          # File browser
    search/                         # Torrent search UI
    seedr/                          # Seedr cloud browser + auth
    settings/                       # App settings
  models/
    app_settings.dart               # Settings data model
    search_result.dart              # Search result model
    seedr_item.dart                 # Seedr folder/file model
    torrent.dart                    # Torrent + download task models
  providers/                        # Riverpod providers
  services/
    background_download_service.dart # Background keep-alive + notifications
    download_service.dart           # HTTP download manager (Dio)
    seedr_service.dart              # Seedr.cc API client
    storage_service.dart            # Hive persistence
    torrent_search_service.dart     # Torrent indexer search API

native/
  torrent_engine/
    include/torrent_engine.h        # C API header
    src/
      sha1.cpp / sha1.h             # SHA-1 implementation
      bencode.cpp / bencode.h       # Bencode parser
      magnet_uri.cpp / magnet_uri.h # Magnet URI parser
      piece_manager.cpp / .h        # Piece assembly + verification
      torrent_engine.cpp            # Bandwidth shaping + health calc
    CMakeLists.txt                  # CMake build (iOS arm64)
  patch_xcode.rb                   # CI: adds Swift file to Xcode project

ios/
  Runner/
    AppDelegate.swift               # FlutterAppDelegate + background handler
    SceneDelegate.swift             # UIWindowSceneDelegate stub
    TorrentFlowNativeService.swift  # Swift native plugin service
    Info.plist                      # App config + background modes
  Flutter/
    Release.xcconfig                # Linker flags for C++ static lib
```

## Building

### Prerequisites
- macOS with Xcode 16+ (or your version)
- Flutter SDK 3.29+ (stable channel)

### Build IPA (unsigned)
```bash
# Install dependencies
flutter pub get

# Build C++ native engine
cd native
cmake -S torrent_engine -B build/ios \
  -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO
cmake --build build/ios --config Release
cp build/ios/Release-iphoneos/libtorrent_engine.a ../ios/Runner/
cd ..

# Patch Xcode project with Swift source
ruby native/patch_xcode.rb

# Build unsigned IPA
flutter build ios --release --no-codesign
mkdir -p build/ipa/Payload
cp -r build/ios/iphoneos/Runner.app build/ipa/Payload/
cd build/ipa
zip -r ../TorrentFlow.ipa Payload/
```

### Install on Device
1. Get the unsigned IPA from `build/TorrentFlow.ipa`
2. Sign with your Apple developer certificate using Sideloadly, AltStore, or Xcode
3. Free accounts: 7-day validity. Paid accounts: permanent installation.

## Design Notes

- **iOS-only** — No Android support. Uses platform-specific Cupertino widgets, Swift APIs, and C++ via FFI.
- **Background torrents** — iOS terminates custom socket connections after ~30s. Active torrents use a keep-alive timer + silent audio. Seedr/HTTP downloads use native `URLSession` which survives app suspension.
- **C++ for performance** — SHA-1, bencode parsing, and piece management run natively via `dart:ffi` (`DynamicLibrary.process()`).
- **Riverpod** — All state is managed via Riverpod providers, not setState or BloC.

## License

MIT — see [LICENSE](LICENSE).
