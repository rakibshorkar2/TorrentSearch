import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../../logging/app_logger.dart';
import '../../models/torrent.dart';
import 'bencode.dart';
import 'torrent_engine.dart';
import 'torrent_downloader.dart';

class TorrentService {
  static TorrentService? _instance;
  DevelopmentTorrentEngine? _engine;
  Future<void>? _initFuture;

  TorrentService._();

  static TorrentService get instance {
    _instance ??= TorrentService._();
    return _instance!;
  }

  DevelopmentTorrentEngine get engine {
    _engine ??= DevelopmentTorrentEngine();
    _initFuture ??= _finishInitialize();
    return _engine!;
  }

  Future<void> initialize() async {
    engine;
    if (_initFuture != null) await _initFuture;
  }

  Future<void> _finishInitialize() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final downloadDir = '${docsDir.path}${Platform.pathSeparator}Downloads';
      await _engine!.initialize(savePath: downloadDir);
      appLogger.i('TorrentService initialized');
    } catch (e) {
      appLogger.e('Failed to initialize torrent engine', error: e);
    }
  }

  Future<String> addMagnet(String magnetUri, {String? name, String? savePath}) async {
    await initialize();
    return engine.addMagnet(magnetUri, name: name, savePath: savePath);
  }

  Future<String> addTorrentFile(String filePath, {String? name, String? savePath}) async {
    await initialize();
    return engine.addTorrentFile(filePath, name: name, savePath: savePath);
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

  Stream<TorrentStatus> updates() {
    _engine ??= DevelopmentTorrentEngine();
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

class DevelopmentTorrentEngine implements TorrentEngine {
  final Map<String, TorrentDownloader> _downloaders = {};
  final Map<String, TorrentStatus> _statuses = {};
  final Map<String, StreamController<DownloadTask>> _taskControllers = {};
  final Map<String, StreamSubscription<DownloadTask>> _taskSubscriptions = {};
  final _updateController = StreamController<TorrentStatus>.broadcast();
  String _savePath = '';
  bool _initialized = false;

  @override
  Future<void> initialize({required String savePath}) async {
    _savePath = savePath;
    _initialized = true;
  }

  @override
  Future<String> addMagnet(String magnetUri, {String? name, String? savePath}) async {
    if (!_initialized) throw StateError('Engine not initialized');
    final id = 'torrent_${DateTime.now().millisecondsSinceEpoch}_${_downloaders.length}';
    final downloader = TorrentDownloader();
    _downloaders[id] = downloader;

    final effectiveSavePath = savePath ?? '$_savePath${Platform.pathSeparator}${name ?? 'download'}';

    final status = TorrentStatus(
      id: id,
      name: name ?? 'Magnet Download',
      state: TorrentState.downloading,
    );
    _statuses[id] = status;
    _updateController.add(status);

    final controller = StreamController<DownloadTask>.broadcast();
    _taskControllers[id] = controller;

    downloader.download(
      magnetUri: magnetUri,
      savePath: effectiveSavePath,
      taskId: id,
      controller: controller,
    );

    final subscription = controller.stream.listen(
      (task) {
        final s = _statuses[id];
        if (s == null) return;
        _statuses[id] = s.copyWith(
          state: _downloadStateToTorrentState(task.status),
          progress: task.progress,
          totalDownloaded: task.downloadedBytes,
          totalSize: task.totalSize,
        );
        _updateController.add(_statuses[id]!);
      },
      onError: (error) {
        final s = _statuses[id];
        if (s != null) {
          _statuses[id] = s.copyWith(state: TorrentState.error, errorMessage: error.toString());
          _updateController.add(s.copyWith(state: TorrentState.error, errorMessage: error.toString()));
        }
        _cleanup(id);
      },
      onDone: () {
        final s = _statuses[id];
        if (s != null && s.state != TorrentState.error && s.state != TorrentState.finished) {
          _statuses[id] = s.copyWith(state: TorrentState.finished, progress: 1.0);
          _updateController.add(s.copyWith(state: TorrentState.finished, progress: 1.0));
        }
        _cleanup(id);
      },
    );
    _taskSubscriptions[id] = subscription;

    return id;
  }

  @override
  Future<String> addTorrentFile(String filePath, {String? name, String? savePath}) async {
    if (!_initialized) throw StateError('Engine not initialized');
    final id = 'torrent_${DateTime.now().millisecondsSinceEpoch}_${_downloaders.length}';
    final status = TorrentStatus(
      id: id,
      name: name ?? 'Torrent Download (.torrent import)',
      state: TorrentState.queued,
    );
    _statuses[id] = status;
    _updateController.add(status);

    final finalSavePath = savePath ?? '$_savePath${Platform.pathSeparator}${name ?? 'download'}';
    try {
      final file = File(filePath);
      final contents = await file.readAsBytes();
      final parsed = Bencode.parseBytes(contents);
      final infoDict = parsed.rawValue('info');
      if (infoDict.isNotEmpty) {
        final hash = sha1.convert(infoDict).toString();
        final magnetUri = 'magnet:?xt=urn:btih:$hash';
        return addMagnet(magnetUri, name: name, savePath: finalSavePath);
      }
    } catch (e) {
      appLogger.e('Failed to parse .torrent file', error: e);
    }
    _cleanup(id);
    return id;
  }

  @override
  void remove(String id) {
    _downloaders[id]?.cancel();
    _downloaders.remove(id);
    _statuses.remove(id);
    _taskSubscriptions.remove(id)?.cancel();
    _taskControllers.remove(id)?.close();
  }

  @override
  void pause(String id) {
    _downloaders[id]?.cancel();
    final s = _statuses[id];
    if (s != null) {
      _statuses[id] = s.copyWith(state: TorrentState.paused);
      _updateController.add(s.copyWith(state: TorrentState.paused));
    }
  }

  @override
  void resume(String id) {
    appLogger.w('Resume not supported in development engine for $id');
  }

  @override
  TorrentStatus? status(String id) => _statuses[id];

  @override
  List<TorrentStatus> allStatuses() => _statuses.values.toList();

  @override
  Stream<TorrentStatus> updates() => _updateController.stream;

  @override
  Future<void> shutdown() async {
    for (final d in _downloaders.values) {
      d.cancel();
    }
    _downloaders.clear();
    _statuses.clear();
    for (final sub in _taskSubscriptions.values) {
      await sub.cancel();
    }
    _taskSubscriptions.clear();
    for (final c in _taskControllers.values) {
      await c.close();
    }
    _taskControllers.clear();
    await _updateController.close();
  }

  void _cleanup(String id) {
    _taskSubscriptions.remove(id)?.cancel();
    _taskControllers.remove(id)?.close();
  }

  static TorrentState _downloadStateToTorrentState(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return TorrentState.downloading;
      case DownloadStatus.completed:
        return TorrentState.finished;
      case DownloadStatus.error:
        return TorrentState.error;
      case DownloadStatus.paused:
        return TorrentState.paused;
      case DownloadStatus.queued:
        return TorrentState.queued;
      default:
        return TorrentState.downloading;
    }
  }
}
