import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/app_settings.dart';
import '../../services/storage_service.dart';
import '../../logging/app_logger.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.read(storageServiceProvider));
});

final screenAwakeProvider = Provider<ScreenAwakeController>((ref) {
  final controller = ScreenAwakeController();
  final settings = ref.read(settingsProvider);
  controller.update(settings);
  ref.listen(settingsProvider, (_, next) async {
    await controller.update(next);
  });
  ref.onDispose(() => controller.dispose());
  return controller;
});

class ScreenAwakeController {
  Timer? _timer;
  Timer? _watchdog;
  DateTime? _expiresAt;
  Future<void>? _lastUpdate;

  Future<void> update(AppSettings settings) async {
    await _lastUpdate;
    _lastUpdate = _doUpdate(settings);
    return _lastUpdate;
  }

  Future<void> _doUpdate(AppSettings settings) async {
    _timer?.cancel();
    _expiresAt = null;

    try {
      if (settings.screenAwakeMinutes != null && settings.screenAwakeMinutes! > 0) {
        final duration = Duration(minutes: settings.screenAwakeMinutes!);
        _expiresAt = DateTime.now().add(duration);
        await WakelockPlus.enable();
        _startWatchdog();
        _timer = Timer(duration, () {
          _disableWakeLock();
        });
      } else {
        await _disableWakeLock();
      }
    } catch (e) {
      appLogger.e('Screen awake error', error: e);
    }
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_expiresAt != null && DateTime.now().isAfter(_expiresAt!)) {
        _disableWakeLock();
      }
    });
  }

  Future<void> _disableWakeLock() async {
    _timer?.cancel();
    _timer = null;
    _watchdog?.cancel();
    _watchdog = null;
    _expiresAt = null;
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }

  void dispose() {
    _timer?.cancel();
    _watchdog?.cancel();
    _disableWakeLock();
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storage;
  bool _disposed = false;

  SettingsNotifier(this._storage) : super(const AppSettings()) {
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final settings = await _storage.loadSettings();
      if (_disposed) return;
      state = settings;
    } catch (e) {
      appLogger.e('Failed to load settings', error: e);
    }
  }

  Future<void> update(AppSettings updated) async {
    state = updated;
    await _storage.saveSettings(updated);
  }
}
