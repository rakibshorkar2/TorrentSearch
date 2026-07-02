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

final screenAwakeProvider = Provider<void>((ref) {
  ref.listen(settingsProvider, (prev, next) {
    _updateWakelock(next);
  });
  ref.onDispose(() {
    _cancelTimer();
    WakelockPlus.disable();
  });
});

Timer? _wakelockTimer;

void _updateWakelock(AppSettings settings) {
  _wakelockTimer?.cancel();
  _wakelockTimer = null;
  if (settings.screenAwakeMinutes != null && settings.screenAwakeMinutes! > 0) {
    WakelockPlus.enable();
    _wakelockTimer = Timer(Duration(minutes: settings.screenAwakeMinutes!), () {
      WakelockPlus.disable();
      _wakelockTimer = null;
    });
  } else {
    WakelockPlus.disable();
  }
}

void _cancelTimer() {
  _wakelockTimer?.cancel();
  _wakelockTimer = null;
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
