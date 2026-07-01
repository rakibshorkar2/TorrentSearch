import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/native/native_service.dart';
import '../models/torrent.dart';
import '../providers/app_providers.dart';
import 'download_service.dart';

class BackgroundDownloadService {
  final NativeTorrentService _native = NativeTorrentService();
  final DownloadService _downloadService;
  final Ref _ref;

  bool _isInitialized = false;
  Timer? _keepAliveTimer;
  StreamSubscription<Duration>? _foregroundSubscription;

  BackgroundDownloadService(this._downloadService, this._ref);

  Future<void> initialize() async {
    if (_isInitialized || !Platform.isIOS) return;
    _isInitialized = true;

    if (await _native.requestNotificationPermission()) {
      await _native.enableBackgroundMode();
    }

    _native.getDeviceModel().then((_) {});

    _startKeepAlive();
  }

  void _startKeepAlive() {
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkActiveDownloads();
    });
  }

  Future<void> _checkActiveDownloads() async {
    final tasks = _downloadService.getTasks();
    final activeTasks = tasks.where((t) => t.status == DownloadStatus.downloading).toList();

    if (activeTasks.isEmpty) {
      // No active torrents - check network to keep connectivity alive
      await _native.getNetworkStatus();
      return;
    }

    // Notify about active downloads in background
    for (final task in activeTasks) {
      if (task.progress > 0 && task.progress < 1) {
        await _native.showLocalNotification(
          title: 'Downloading: ${task.title}',
          body: '${task.formattedProgress} — ${task.formattedSpeed}',
          payload: task.id,
        );
      }
    }

    // If WiFi-only mode, check connection
    final settings = _ref.read(settingsProvider);
    if (settings.wifiOnly) {
      final isWifi = await _native.isWifiConnected();
      if (!isWifi) {
        for (final task in activeTasks) {
          _downloadService.pause(task.id);
        }
      }
    }
  }

  Future<void> downloadFromSeedr({
    required String title,
    required String url,
    required String destination,
  }) async {
    final taskId = 'seedr_${DateTime.now().millisecondsSinceEpoch}';

    if (_downloadService.getTasks().length >= _ref.read(settingsProvider).maxConcurrentDownloads) {
      throw Exception('Maximum concurrent downloads reached');
    }

    // Use Background URLSession for HTTP downloads from Seedr
    await _native.scheduleBackgroundDownload(
      url: url,
      destination: destination,
      taskId: taskId,
    );

    await _native.showLocalNotification(
      title: 'Download Started',
      body: title,
    );
  }

  Future<void> notifyDownloadComplete(String title) async {
    await _native.showLocalNotification(
      title: 'Download Complete',
      body: title,
    );
  }

  Future<void> notifyDownloadError(String title, String error) async {
    await _native.showLocalNotification(
      title: 'Download Failed',
      body: '$title: $error',
    );
  }

  Future<Map<String, dynamic>> getStorageInfo() => _native.getStorageInfo();
  Future<int> getThermalState() => _native.getThermalState();
  Future<String> getDeviceModel() => _native.getDeviceModel();
  Future<bool> isWifiConnected() => _native.isWifiConnected();
  Future<Map<String, dynamic>> getNetworkStatus() => _native.getNetworkStatus();

  void dispose() {
    _keepAliveTimer?.cancel();
    _foregroundSubscription?.cancel();
  }
}
