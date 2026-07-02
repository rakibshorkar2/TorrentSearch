import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/native/native_service.dart';
import '../models/torrent.dart';
import '../providers/downloads/download_providers.dart';
import '../logging/app_logger.dart';
import '../providers/settings/settings_providers.dart';
import 'download_service.dart';

class BackgroundDownloadService {
  final NativeTorrentService _native = NativeTorrentService();
  final DownloadService _downloadService;
  final Ref _ref;

  bool _isInitialized = false;
  Timer? _keepAliveTimer;
  final Map<String, DownloadTask> _pendingBackgroundTasks = {};

  BackgroundDownloadService(this._downloadService, this._ref);

  Future<void> initialize() async {
    if (_isInitialized || !Platform.isIOS) return;
    _isInitialized = true;

    if (await _native.requestNotificationPermission()) {
      await _native.enableBackgroundMode();
    }

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

    if (activeTasks.isEmpty) return;

    for (final task in activeTasks) {
      if (task.progress > 0 && task.progress < 1) {
        await _native.showLocalNotification(
          title: 'Downloading: ${task.title}',
          body: '${task.formattedProgress} — ${task.formattedSpeed}',
          payload: task.id,
        );
      }
    }

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
    final provider = _ref.read(downloadTasksProvider.notifier);
    final stream = provider.addDownload(
      title: title,
      url: url,
      savePath: destination,
    );

    final taskId = await stream.first.then((t) => t.id);

    _pendingBackgroundTasks[taskId] = _downloadService.getTask(taskId)!;

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

  void handleBackgroundDownloadComplete(String taskId, {String? error}) {
    final task = _pendingBackgroundTasks.remove(taskId);
    if (task == null) return;

    if (error != null) {
      _downloadService.remove(taskId);
      notifyDownloadError(task.title, error);
      appLogger.e('Background download $taskId failed: $error');
    } else {
      final completedTask = task.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        completedAt: DateTime.now(),
      );
      _ref.read(downloadTasksProvider.notifier).updateTask(completedTask);
      notifyDownloadComplete(task.title);
      appLogger.i('Background download $taskId completed');
    }
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
  }
}
