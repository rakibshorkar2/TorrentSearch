import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

final class TorrentEngine {
  late final double Function(int seeders, int leechers) calculateHealth;
  late final Pointer<Utf8> Function(Pointer<Utf8> magnetUri) magnetParse;
  late final void Function(Pointer<Utf8> result) magnetFree;
  late final Pointer<Utf8> Function(Pointer<Utf8> bencodeData) bencodeParse;
  late final void Function(Pointer<Utf8> result) bencodeFree;

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

    try {
      final magnetParseFn = _lib.lookupFunction<
        Pointer<Utf8> Function(Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>)
      >('magnet_parse');
      magnetParse = magnetParseFn;
    } catch (_) {}

    try {
      final magnetFreeFn = _lib.lookupFunction<
        Void Function(Pointer<Utf8>),
        void Function(Pointer<Utf8>)
      >('magnet_free');
      magnetFree = magnetFreeFn;
    } catch (_) {}

    try {
      final bencodeParseFn = _lib.lookupFunction<
        Pointer<Utf8> Function(Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>)
      >('bencode_parse');
      bencodeParse = bencodeParseFn;
    } catch (_) {}

    try {
      final bencodeFreeFn = _lib.lookupFunction<
        Void Function(Pointer<Utf8>),
        void Function(Pointer<Utf8>)
      >('bencode_free');
      bencodeFree = bencodeFreeFn;
    } catch (_) {}
  }

  String? parseMagnet(String magnetUri) {
    try {
      final uriPtr = magnetUri.toNativeUtf8();
      final resultPtr = magnetParse(uriPtr);
      calloc.free(uriPtr);
      final result = resultPtr.toDartString();
      magnetFree(resultPtr);
      return result;
    } catch (_) {
      return null;
    }
  }

  String? parseBencode(String data) {
    try {
      final dataPtr = data.toNativeUtf8();
      final resultPtr = bencodeParse(dataPtr);
      calloc.free(dataPtr);
      final result = resultPtr.toDartString();
      bencodeFree(resultPtr);
      return result;
    } catch (_) {
      return null;
    }
  }
}
