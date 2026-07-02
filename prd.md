# Master Prompt — Build a Native-Feeling iOS Torrent Downloader (Flutter)

---

You are an expert Flutter, Dart, iOS and networking engineer.

Your goal is to build a **production-quality Flutter application** that runs on **iPhone (iOS only)** and is intended for **personal sideloading**.

The application is **NOT a torrent search engine** and **NOT a media piracy application**.

Its only purpose is to download files from:

* .torrent files
* magnet links

The user supplies the torrent.

No indexing websites.
No scraping.
No search feature.

The finished project must compile into an **unsigned IPA** through **GitHub Actions** on macOS for later sideloading.

---

# Project Name

TorrentFlow

Alternative names:

* TorrentDrop
* MagnetFlow
* TorrentDock
* TorrentBox

---

# Tech Stack

Latest stable Flutter

Latest Dart

Riverpod

Go Router

Flutter Hooks (optional)

Hive or Isar

Freezed

json_serializable

path_provider

file_picker

url_launcher

share_plus

receive_sharing_intent

uni_links

permission_handler

device_info_plus

package_info_plus

connectivity_plus

---

# Torrent Engine

The app MUST use a real BitTorrent engine.

Preferred order:

libtorrent via FFI

or

a mature Dart torrent implementation

or

a lightweight native Swift wrapper around libtorrent.

The engine must support

* BitTorrent v1
* Magnet links
* DHT
* PEX
* Trackers
* Resume downloading
* Fast resume data
* Sequential download option
* Piece verification

---

# UI

Must feel like a native iOS application.

Requirements

Liquid Glass inspired design

Large navigation titles

Blur backgrounds

Rounded cards

Smooth animations

60 FPS

Haptic feedback

Native Cupertino widgets wherever appropriate.

Dark mode

Light mode

Automatic theme

SF Symbols icons

No Material Design appearance.

---

# Navigation

Bottom Navigation

Downloads

Add Torrent

Settings

---

# Downloads Page

Shows all torrents.

Each card displays

Torrent name

Progress bar

Downloaded

Remaining

Download speed

Upload speed

Peers

Seeds

ETA

Status

Current file

Pause button

Resume button

Delete button

Swipe actions

Tap opens details.

---

# Torrent Details

Displays

Torrent information

Tracker list

Connected peers

Files

Piece progress

Hash

Creation date

Comment

Size

Downloaded

Uploaded

Ratio

Availability

Logs

---

# Add Torrent Page

Two large buttons.

## Magnet Link

Paste magnet

Paste from clipboard

Open from Share Sheet

Validate link

Start download

---

## Torrent File

Import using Files app

Drag and Drop support

Recent files

Validate torrent metadata

---

# Magnet Handling

Support

magnet:?xt=

Automatically parse

Display

Name

Trackers

Hash

Metadata progress

Before download.

---

# Open Magnet Links

Support opening from

Safari

Chrome

Firefox

Other browsers

Support

Share Sheet

Open In

Custom URL Scheme

Universal Links if applicable.

---

# File Browser

Show downloaded files.

Folders

Move

Rename

Delete

Share

Preview supported files

Sort

Search

Grid/List toggle

---

# Download Folder

Application Documents

Create

Downloads/

Each torrent inside its own folder.

Example

Downloads/

Ubuntu ISO/

movie/

Linux/

---

# Torrent Controls

Pause

Resume

Force recheck

Force announce

Remove download only

Remove torrent and data

Sequential download

Bandwidth priority

Move download

Rename

---

# Settings

Default download folder

Auto start torrents

Maximum downloads

Maximum active torrents

Maximum peers

Maximum upload slots

Connection timeout

Port

Encryption

Sequential mode default

Background keep-alive options

Storage information

Cache size

Clear cache

Theme

About

---

# Performance

Support torrents over 100 GB.

Thousands of files.

Low RAM usage.

Efficient disk writes.

Avoid UI jank.

---

# Persistence

Remember

Downloads

Progress

Paused state

Resume data

Settings

Recent torrents

Even after app restart.

---

# Notifications

Local notifications

Download completed

Torrent added

Errors

Paused

Storage full

---

# Error Handling

Invalid torrent

Invalid magnet

No storage

Disk full

Tracker timeout

Network unavailable

Metadata failed

Hash mismatch

Permission denied

Graceful recovery.

---

# Clipboard

Automatically detect

Magnet links

Offer

Paste and Download

---

# Share Extension Support

Accept

.torrent

magnet links

Files

Text

---

# Background Behavior

iOS severely limits background execution.

Design accordingly:

* Continue downloading while the app remains active or within the limited background time granted by iOS.
* Save torrent session state frequently so downloads resume quickly when the app is reopened.
* Handle interruptions gracefully (phone lock, app termination, low memory).

Do not claim unlimited background torrent downloading unless using platform capabilities that actually permit it.

---

# Storage

Calculate

Remaining storage

Downloaded today

Downloaded total

Active size

Free space

---

# Security

Validate torrents

Prevent path traversal

Prevent invalid filenames

Verify pieces

Handle corrupt resume data

No analytics

No advertisements

No tracking

Entirely offline except for BitTorrent networking.

---

# Architecture

Feature-first architecture.

Example

lib/

features/

downloads/

torrent/

settings/

shared/

core/

services/

repositories/

models/

widgets/

Use

Repository Pattern

Dependency Injection

Riverpod providers

Clean Architecture principles

---

# Code Quality

Strict linting

Null safety

Well documented code

Reusable widgets

No duplicated logic

Modular code

Small files

Meaningful naming

Unit tests for parsing, persistence, and core logic where practical.

---

# GitHub Actions

Provide a complete macOS workflow that:

* Installs Flutter
* Resolves dependencies
* Builds the iOS project
* Produces an unsigned `.app`
* Packages an unsigned `.ipa`
* Uploads the IPA as a workflow artifact

The workflow should be reproducible with a standard Flutter iOS project and avoid requiring Apple code signing.

---

# Deliverables

The AI agent should generate:

* Complete Flutter project
* iOS-compatible code
* Native integration for the BitTorrent engine (FFI or Swift wrapper)
* Responsive Cupertino UI
* State management
* Persistent storage
* Import/export support for `.torrent` files
* Magnet link handling
* Share Sheet integration
* Custom URL scheme for `magnet:` links
* Robust error handling
* GitHub Actions workflow for building an unsigned IPA
* Clear README with setup, build, and sideloading instructions

The resulting app should feel polished, performant, and native on an iPhone while remaining focused on its single purpose: downloading content from user-provided `.torrent` files and magnet links.
