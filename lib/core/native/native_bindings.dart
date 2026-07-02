import 'dart:ffi';
import 'dart:io';

typedef _CalcHealthC = Double Function(Int32, Int32);
typedef _CalcHealthDart = double Function(int, int);

final class NativeTorrentBindings {
  late final double Function(int seeders, int leechers) calculateHealth;

  late final DynamicLibrary _lib;

  NativeTorrentBindings() : _lib = _load() {
    _bind();
  }

  static DynamicLibrary _load() {
    if (Platform.isIOS) return DynamicLibrary.process();
    throw UnsupportedError('NativeTorrentBindings requires iOS');
  }

  void _bind() {
    final calcHealth = _lib.lookupFunction<_CalcHealthC, _CalcHealthDart>('calculate_health');
    calculateHealth = calcHealth;
  }
}
