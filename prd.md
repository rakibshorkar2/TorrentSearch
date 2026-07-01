# Master Prompt — Build a Premium iOS Flutter App

## Project Name

**TorrentFlow**

*A premium iPhone download manager with native iOS aesthetics, direct BitTorrent support, cloud torrent integration, and an exceptional user experience.*

---

# Objective

Create a **Flutter application exclusively for iOS** that feels indistinguishable from a professionally designed native iOS app.

Target device:

* iPhone 15 Pro
* Latest stable iOS SDK
* Portrait orientation
* Responsive for all iPhones
* Optimized for OLED displays
* 60/120Hz smooth animations

This app is intended for **personal use**.

---

# Primary Goals

The app should combine:

* Direct BitTorrent downloading
* Magnet link support
* .torrent file support
* Torrent searching using user-configured or freely available sources
* Seedr cloud integration
* Modern download manager
* Beautiful iOS UI
* Native-feeling animations
* Excellent performance
* Low memory usage
* Stable networking

---

# Design Philosophy

The UI must feel like it was designed by Apple's Human Interface team.

Avoid Material Design.

Follow Apple's Human Interface Guidelines.

The experience should resemble Apple's first-party apps.

The interface should feel:

* elegant
* lightweight
* premium
* fluid
* responsive
* uncluttered

---

# Visual Style

Create a modern Liquid Glass aesthetic inspired by recent iOS design trends.

Use:

* translucent glass surfaces
* soft blur
* layered depth
* smooth shadows
* subtle gradients
* rounded corners
* vibrant highlights
* animated lighting
* premium spacing
* beautiful typography

No heavy borders.

No cheap gradients.

No clutter.

Everything should breathe.

---

# Navigation

Use a native iOS bottom tab bar.

Tabs:

1. Search
2. Downloads
3. Seedr
4. Settings

Use SF Symbols where appropriate.

Navigation transitions should match native iOS.

---

# Search Tab

Purpose:

Find torrents from user-configured or freely available sources.

Features:

* beautiful search page
* large search field
* recent searches
* trending section (optional)
* categories
* filters
* sorting

Filters:

* size
* seeders
* upload date
* category

Result cards should display:

* title
* size
* seeders
* leechers
* health indicator
* upload date

Actions:

* Open details
* Add via magnet link
* Import .torrent file

Support deep linking so the app can open `magnet:` links from Safari or other apps.

---

# Torrent Details

Display:

* title
* size
* files
* trackers
* comments (if available)
* peers
* health
* piece information

Allow:

* select files
* rename download
* choose destination
* start download

---

# Downloads Tab

Modern download manager.

Each download card includes:

* thumbnail (if available)
* title
* progress ring
* progress bar
* percentage
* download speed
* upload speed
* ETA
* peers
* seeders
* remaining size

Actions:

* pause
* resume
* stop
* delete
* share
* reveal files

Support:

* multiple simultaneous downloads
* queue
* priorities
* sequential download
* bandwidth limits
* retry logic
* resume after restart
* integrity verification

The user will generally keep the app open while downloading.

---

# Seedr Tab

Integrate with the user's Seedr account if supported by the service's API.

Features:

* login/logout
* cloud storage usage
* browse folders
* add magnet links
* upload .torrent files
* monitor cloud download progress
* stream supported media (if available)
* download completed files to device
* delete
* rename
* organize files

The UI should match the rest of the application.

---

# Settings

Include:

General

Downloads

Network

Appearance

About

Options:

SOCKS5 proxy

Connection timeout

Maximum peers

Maximum connections

Download speed limit

Upload speed limit

Wi-Fi only option

Auto import magnet links

Notifications

Theme (System/Light/Dark)

Storage information

App version

Diagnostics

---

# File Browser

Modern iOS file browser.

Features:

* folders
* thumbnails
* sorting
* search
* preview
* rename
* delete
* move
* share
* open in Files

---

# Networking

Architecture:

Flutter UI

Native Swift plugin where required

Reliable networking layer

Background-safe architecture where supported by iOS

Persistent sessions

Graceful reconnects

Automatic retries

---

# Performance

Requirements:

Fast startup

Smooth scrolling

No UI jank

Lazy loading

Efficient caching

Minimal rebuilds

Memory efficient

Battery conscious

---

# Animations

Use premium animations.

Examples:

glass morphing

matched geometry

hero transitions

spring animations

interactive gestures

parallax

subtle haptics

micro-interactions

Everything should feel alive.

---

# Accessibility

Support:

VoiceOver

Dynamic Type

High contrast

Large touch targets

Reduced Motion

---

# Security

Store sensitive information securely.

Use Keychain for credentials and tokens.

Avoid logging secrets.

Validate inputs.

Handle network failures gracefully.

---

# Code Quality

Use a clean architecture with clear separation of concerns.

Suggested layers:

* Presentation
* Domain
* Data
* Services
* Repository
* Models

State management:

Riverpod

Routing:

go_router

Networking:

Dio

Storage:

Hive or Isar for local persistence

Secure storage:

flutter_secure_storage

Use dependency injection.

Write modular, testable code.

---

# Native iOS Feel

The application should feel native in every interaction:

* iOS navigation bar
* native context menus
* swipe gestures
* haptic feedback
* pull to refresh
* smooth physics
* native dialogs
* native share sheet
* native document picker
* native blur effects

Avoid Material widgets where iOS equivalents exist.

---

# Error Handling

Handle gracefully:

Network failures

Proxy failures

Authentication errors

Disk full

Connection timeouts

Interrupted downloads

Malformed torrent files

Unavailable peers

User cancellation

Display clear, non-technical error messages.

---

# Final Deliverables

Provide:

* Complete Flutter source code
* iOS project configured and ready to build
* Well-organized folder structure
* Clean, documented code
* Setup instructions
* Dependency list
* Build instructions
* Test coverage for critical logic
* README with screenshots/placeholders
* GitHub Actions workflow to produce an unsigned IPA suitable for manual signing

The finished application should feel like a premium App Store-quality iPhone app, with exceptional polish, fluid performance, and a refined native iOS experience while supporting personal management of torrent workflows, cloud integration, and downloaded files.
