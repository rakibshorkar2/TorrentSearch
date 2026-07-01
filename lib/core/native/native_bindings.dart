import 'dart:ffi';
import 'dart:io';

final class TorrentEngine {
  late final double Function(int seeders, int leechers) calculateHealth;

  late final DynamicLibrary _lib;

  TorrentEngine() : _lib = _load() {
    _bind();
  }

  static DynamicLibrary _load() {
    if (Platform.isIOS) return DynamicLibrary.process();
    throw UnsupportedError('TorrentEngine requires iOS');
  }

  void _bind() {
    final calcHealth = _lib.lookupFunction<
      Double Function(Int32, Int32),
      double Function(int, int)
    >('calculate_health');
    calculateHealth = calcHealth;
  }
}
