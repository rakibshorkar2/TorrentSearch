If you want to build an iTorrent-like app **in Flutter**, you'll need a combination of Flutter packages and native iOS code. There is **no single Flutter package** that provides a complete torrent client.

Here's a recommended stack.

| Purpose                          | Library                                                                                |
| -------------------------------- | -------------------------------------------------------------------------------------- |
| Torrent engine                   | [libtorrent](https://github.com/arvidn/libtorrent?utm_source=chatgpt.com) (native C++) |
| Flutter ↔ native bridge          | Dart FFI (`dart:ffi`)                                                                  |
| State management                 | Riverpod                                                                               |
| Local database                   | Hive or Isar                                                                           |
| File picker                      | file_picker                                                                            |
| Save to Files app                | path_provider                                                                          |
| Permissions                      | permission_handler                                                                     |
| Magnet link support              | Native iOS URL Scheme + MethodChannel                                                  |
| Background downloads             | Native iOS implementation (no Flutter-only solution)                                   |
| Dynamic Island / Live Activities | Native Swift using ActivityKit                                                         |
| Notifications                    | flutter_local_notifications                                                            |
| Share files                      | share_plus                                                                             |
| RSS feeds                        | webfeed                                                                                |
| HTTP                             | dio                                                                                    |
| WebDAV                           | Native implementation or embedded server package                                       |
| Logging                          | logger                                                                                 |

### The most important component: libtorrent

Everything revolves around **libtorrent**.

```
Flutter UI
      │
Riverpod
      │
Torrent Manager (Dart)
      │
Dart FFI
      │
libtorrent (C++)
      │
Trackers
DHT
Peers
```

Without libtorrent, you'd effectively have to implement the BitTorrent protocol yourself, which is a major undertaking.

### Flutter packages alone are not enough

Several key iOS features require native Swift code:

* Live Activities
* Dynamic Island
* Background execution
* Magnet link registration
* Files app document integration
* Share Extension

These are exposed to Flutter through Platform Channels or FFI.

### Suggested architecture

```
Flutter
├── Browser
├── Search
├── Torrent List
├── Downloads
├── Settings
├── RSS
└── Seedr (optional)

Riverpod
│
Torrent Service (Dart)
│
FFI
│
libtorrent
│
Swift Plugin
├── ActivityKit
├── WidgetKit
├── BackgroundTasks
├── Files App
└── Notifications
```

### iOS frameworks you'll still use

Even in a Flutter app, you'll likely integrate these Apple frameworks on the native side:

* ActivityKit
* WidgetKit
* BackgroundTasks
* UniformTypeIdentifiers
* UserNotifications

### If your goal is to match iTorrent

If you're aiming for features like:

* Native-feeling UI
* Magnet links
* Torrent downloads
* Sequential streaming
* Background downloads
* Live Activities / Dynamic Island
* Files app integration
* RSS
* WebDAV
* High performance

then the key dependency is **libtorrent**, with Flutter handling the UI and business logic while Swift bridges to iOS-specific capabilities.

If this is a **personal app for your iPhone 15 Pro only**, Flutter can absolutely be used, but expect roughly **15–25% of the project** (primarily iOS integrations) to be written in Swift alongside your Flutter code.
