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
  bool _initialized = false;

  TorrentService._();

  static TorrentService get instance {
    _instance ??= TorrentService._();
    return _instance!;
  }

  TorrentEngine get engine {
    if (_engine == null) initialize();
    return _engine!;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _engine = _createEngine();
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final downloadDir = '${docsDir.path}${Platform.pathSeparator}Downloads';
      await _engine!.initialize(savePath: downloadDir);
      _initialized = true;
      appLogger.i('TorrentService initialized with ${_engine.runtimeType}');
    } catch (e) {
      appLogger.e('Failed to initialize torrent engine', error: e);
      _engine = _createEngine();
      await _engine!.initialize(savePath: '/tmp');
      _initialized = true;
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

  Future<String> addMagnet(String magnetUri, {String? name}) {
    return engine.addMagnet(magnetUri, name: name);
  }

  Future<String> addTorrentFile(String filePath, {String? name}) {
    return engine.addTorrentFile(filePath, name: name);
  }

  void remove(String id) => engine.remove(id);

  void pause(String id) => engine.pause(id);

  void resume(String id) => engine.resume(id);

  TorrentStatus? status(String id) => engine.status(id);

  List<TorrentStatus> allStatuses() => engine.allStatuses();

  Stream<TorrentStatus> updates() => engine.updates();

  Future<void> shutdown() async {
    if (_engine != null) {
      await _engine!.shutdown();
    }
    _initialized = false;
  }
}
