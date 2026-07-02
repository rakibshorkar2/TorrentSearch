import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../logging/app_logger.dart';
import 'torrent_engine.dart';
import 'development_engine.dart';
import 'libtorrent_engine.dart';

class TorrentService {
  static TorrentService? _instance;
  TorrentEngine? _engine;
  Future<void>? _initFuture;

  TorrentService._();

  static TorrentService get instance {
    _instance ??= TorrentService._();
    return _instance!;
  }

  TorrentEngine get engine {
    if (_engine == null) {
      _engine = _createEngine();
      _initFuture ??= _finishInitialize();
    }
    return _engine!;
  }

  Future<void> initialize() async {
    engine; // trigger lazy init
    if (_initFuture != null) await _initFuture;
  }

  Future<void> _finishInitialize() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final downloadDir = '${docsDir.path}${Platform.pathSeparator}Downloads';
      await _engine!.initialize(savePath: downloadDir);
      appLogger.i('TorrentService initialized with ${_engine.runtimeType}');
    } catch (e) {
      appLogger.e('Failed to initialize torrent engine', error: e);
      _engine = _createEngine();
      await _engine!.initialize(savePath: '/tmp');
    }
  }

  static TorrentEngine _createEngine() {
    if (Platform.isIOS) {
      try {
        return LibTorrentEngine();
      } catch (e) {
        appLogger.w('LibTorrentEngine not available, using development engine', error: e);
        return DevelopmentTorrentEngine();
      }
    }
    return DevelopmentTorrentEngine();
  }

  Future<String> addMagnet(String magnetUri, {String? name}) async {
    await initialize();
    return engine.addMagnet(magnetUri, name: name);
  }

  Future<String> addTorrentFile(String filePath, {String? name}) async {
    await initialize();
    return engine.addTorrentFile(filePath, name: name);
  }

  Future<void> remove(String id) async {
    await initialize();
    engine.remove(id);
  }

  Future<void> pause(String id) async {
    await initialize();
    engine.pause(id);
  }

  Future<void> resume(String id) async {
    await initialize();
    engine.resume(id);
  }

  Future<TorrentStatus?> status(String id) async {
    await initialize();
    return engine.status(id);
  }

  Future<List<TorrentStatus>> allStatuses() async {
    await initialize();
    return engine.allStatuses();
  }

  Stream<TorrentStatus> updates() {
    _engine ??= _createEngine();
    _initFuture ??= _finishInitialize();
    return engine.updates();
  }

  Future<void> shutdown() async {
    if (_engine != null) {
      await _engine!.shutdown();
      _engine = null;
    }
    _initFuture = null;
  }
}
