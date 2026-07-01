import 'dart:io';
import 'package:flutter/services.dart';
import 'native_bindings.dart';

typedef BackgroundDownloadCallback = void Function(String taskId, {String? error});

class NativeTorrentService {
  static final NativeTorrentService _instance = NativeTorrentService._();
  factory NativeTorrentService() => _instance;
  NativeTorrentService._();

  TorrentEngine? _engine;
  static const _channel = MethodChannel('com.torrentflow/native');
  BackgroundDownloadCallback? _onBackgroundDownloadComplete;

  bool get isAvailable => Platform.isIOS;

  TorrentEngine get engine {
    _engine ??= TorrentEngine();
    return _engine!;
  }

  void initialize({BackgroundDownloadCallback? onBackgroundDownloadComplete}) {
    _onBackgroundDownloadComplete = onBackgroundDownloadComplete;
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'backgroundDownloadComplete':
        final args = call.arguments as Map<dynamic, dynamic>;
        final taskId = args['taskId'] as String? ?? '';
        final error = args['error'] as String?;
        _onBackgroundDownloadComplete?.call(taskId, error: error);
        return null;
      default:
        return null;
    }
  }

  Future<bool> registerBackgroundTask(String taskId) async {
    try {
      return await _channel.invokeMethod('registerBackgroundTask', {'taskId': taskId});
    } catch (_) {
      return false;
    }
  }

  Future<bool> unregisterBackgroundTask(String taskId) async {
    try {
      return await _channel.invokeMethod('unregisterBackgroundTask', {'taskId': taskId});
    } catch (_) {
      return false;
    }
  }

  Future<void> scheduleBackgroundDownload({
    required String url,
    required String destination,
    required String taskId,
  }) async {
    await _channel.invokeMethod('scheduleBackgroundDownload', {
      'url': url,
      'destination': destination,
      'taskId': taskId,
    });
  }

  Future<Map<String, dynamic>> getNetworkStatus() async {
    try {
      return await _channel.invokeMethod('getNetworkStatus') ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<bool> isWifiConnected() async {
    try {
      final status = await _channel.invokeMethod('getNetworkStatus');
      return status?['isWifi'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      return await _channel.invokeMethod('requestNotificationPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _channel.invokeMethod('showLocalNotification', {
      'title': title,
      'body': body,
      'payload': payload,
    });
  }

  Future<String?> getKeychainValue(String key) async {
    try {
      return await _channel.invokeMethod('getKeychainValue', {'key': key});
    } catch (_) {
      return null;
    }
  }

  Future<void> setKeychainValue(String key, String value) async {
    await _channel.invokeMethod('setKeychainValue', {'key': key, 'value': value});
  }

  Future<void> deleteKeychainValue(String key) async {
    await _channel.invokeMethod('deleteKeychainValue', {'key': key});
  }

  Future<String> getDeviceModel() async {
    try {
      return await _channel.invokeMethod('getDeviceModel') ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<int> getThermalState() async {
    try {
      return await _channel.invokeMethod('getThermalState') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      return await _channel.invokeMethod('getStorageInfo') ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<void> enableBackgroundMode() async {
    await _channel.invokeMethod('enableBackgroundMode');
  }
}
