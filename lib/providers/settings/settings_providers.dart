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
  ref.listen(settingsProvider, (prev, next) {
    controller.update(next);
  });
  ref.onDispose(() => controller.dispose());
  return controller;
});

class ScreenAwakeController {
  Timer? _timer;

  void update(AppSettings settings) {
    _timer?.cancel();
    _timer = null;
    try {
      if (settings.screenAwakeMinutes != null && settings.screenAwakeMinutes! > 0) {
        WakelockPlus.enable();
        _timer = Timer(Duration(minutes: settings.screenAwakeMinutes!), () {
          try {
            WakelockPlus.disable();
          } catch (_) {}
          _timer = null;
        });
      } else {
        WakelockPlus.disable();
      }
    } catch (e) {
      appLogger.e('Screen awake error', error: e);
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    try {
      WakelockPlus.disable();
    } catch (_) {}
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storage;

  SettingsNotifier(this._storage) : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _storage.loadSettings();
      if (!mounted) return;
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
