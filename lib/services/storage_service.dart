import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/torrent.dart';
import '../models/app_settings.dart';
import '../core/constants/app_constants.dart';
import '../logging/app_logger.dart';

class StorageService {
  late Box<String> _settingsBox;
  late Box<String> _downloadsBox;
  late Box<String> _searchHistoryBox;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox<String>(AppConstants.hiveBoxSettings);
    _downloadsBox = await Hive.openBox<String>(AppConstants.hiveBoxDownloads);
    _searchHistoryBox = await Hive.openBox<String>(AppConstants.hiveBoxSearchHistory);
  }

  // Settings
  Future<AppSettings> loadSettings() async {
    final json = _settingsBox.get('settings');
    if (json == null) return const AppSettings();
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return AppSettings(
        useDarkMode: map['useDarkMode'] as bool? ?? true,
        followSystemTheme: map['followSystemTheme'] as bool? ?? true,
        wifiOnly: map['wifiOnly'] as bool? ?? false,
        autoImportMagnet: map['autoImportMagnet'] as bool? ?? true,
        notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
        maxConcurrentDownloads: map['maxConcurrentDownloads'] as int? ?? 3,
        maxPeers: map['maxPeers'] as int? ?? 50,
        maxConnections: map['maxConnections'] as int? ?? 50,
        downloadSpeedLimit: map['downloadSpeedLimit'] as int? ?? 0,
        uploadSpeedLimit: map['uploadSpeedLimit'] as int? ?? 0,
        connectionTimeout: map['connectionTimeout'] as int? ?? 10,
        hapticFeedback: map['hapticFeedback'] as bool? ?? true,
        confirmBeforeDownload: map['confirmBeforeDownload'] as bool? ?? true,
        autoDownloadCompletedSeedr: map['autoDownloadCompletedSeedr'] as bool? ?? false,
        saveSearchHistory: map['saveSearchHistory'] as bool? ?? true,
        screenAwakeMinutes: map['screenAwakeMinutes'] as int?,
      );
    } catch (e) {
      appLogger.e('Failed to parse settings', error: e);
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final map = {
      'useDarkMode': settings.useDarkMode,
      'followSystemTheme': settings.followSystemTheme,
      'wifiOnly': settings.wifiOnly,
      'autoImportMagnet': settings.autoImportMagnet,
      'notificationsEnabled': settings.notificationsEnabled,
      'maxConcurrentDownloads': settings.maxConcurrentDownloads,
      'maxPeers': settings.maxPeers,
      'maxConnections': settings.maxConnections,
      'downloadSpeedLimit': settings.downloadSpeedLimit,
      'uploadSpeedLimit': settings.uploadSpeedLimit,
      'connectionTimeout': settings.connectionTimeout,
      'hapticFeedback': settings.hapticFeedback,
      'confirmBeforeDownload': settings.confirmBeforeDownload,
      'autoDownloadCompletedSeedr': settings.autoDownloadCompletedSeedr,
      'saveSearchHistory': settings.saveSearchHistory,
      'screenAwakeMinutes': settings.screenAwakeMinutes,
    };
    await _settingsBox.put('settings', jsonEncode(map));
  }

  // Downloads
  Future<List<DownloadTask>> loadDownloads() async {
    final json = _downloadsBox.get('tasks');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((item) => _downloadFromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      appLogger.e('Failed to parse downloads', error: e);
      return [];
    }
  }

  Future<void> saveDownloads(List<DownloadTask> tasks) async {
    final list = tasks.map((t) => _downloadToMap(t)).toList();
    await _downloadsBox.put('tasks', jsonEncode(list));
  }

  // Search History
  Future<List<String>> loadSearchHistory() async {
    final json = _searchHistoryBox.get('history');
    if (json == null) return [];
    try {
      return (jsonDecode(json) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSearchHistory(List<String> history) async {
    await _searchHistoryBox.put('history', jsonEncode(history));
  }

  Future<void> addSearchQuery(String query) async {
    final history = await loadSearchHistory();
    history.remove(query);
    history.insert(0, query);
    if (history.length > 20) history.removeLast();
    await saveSearchHistory(history);
  }

  // Secure Storage
  Future<String?> getSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> setSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  Map<String, dynamic> _downloadToMap(DownloadTask task) {
    return {
      'id': task.id,
      'title': task.title,
      'infoHash': task.infoHash,
      'magnetUri': task.magnetUri,
      'torrentPath': task.torrentPath,
      'totalSize': task.totalSize,
      'downloadedBytes': task.downloadedBytes,
      'uploadedBytes': task.uploadedBytes,
      'status': task.status.index,
      'progress': task.progress,
      'savePath': task.savePath,
      'addedAt': task.addedAt.toIso8601String(),
      'completedAt': task.completedAt?.toIso8601String(),
      'selectedFileIndices': task.selectedFileIndices,
      'downloadLimit': task.downloadLimit,
      'uploadLimit': task.uploadLimit,
      'priority': task.priority.index,
    };
  }

  DownloadTask _downloadFromMap(Map<String, dynamic> map) {
    return DownloadTask(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      infoHash: map['infoHash']?.toString(),
      magnetUri: map['magnetUri']?.toString(),
      torrentPath: map['torrentPath']?.toString(),
      totalSize: map['totalSize'] as int? ?? 0,
      downloadedBytes: map['downloadedBytes'] as int? ?? 0,
      uploadedBytes: map['uploadedBytes'] as int? ?? 0,
      status: DownloadStatus.values[map['status'] as int? ?? 0],
      progress: (map['progress'] as num?)?.toDouble() ?? 0,
      savePath: map['savePath'] as String? ?? '',
      addedAt: DateTime.tryParse(map['addedAt']?.toString() ?? '') ?? DateTime.now(),
      completedAt: DateTime.tryParse(map['completedAt']?.toString() ?? ''),
      selectedFileIndices: (map['selectedFileIndices'] as List?)?.cast<int>() ?? [],
      downloadLimit: map['downloadLimit'] as int?,
      uploadLimit: map['uploadLimit'] as int?,
      priority: DownloadPriority.values[map['priority'] as int? ?? 1],
    );
  }
}
