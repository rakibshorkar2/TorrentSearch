import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/torrent.dart';
import '../core/constants/app_constants.dart';
import '../logging/app_logger.dart';
import 'torrent_engine/torrent_service.dart';
import 'torrent_engine/torrent_engine.dart' as engine;

class DownloadService {
  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, StreamController<DownloadTask>> _controllers = {};
  final List<DownloadTask> _tasks = [];
  final Map<String, int> _retryCounts = {};
  int _taskCounter = 0;
  static const int _maxRetries = 3;

  DownloadService() : _dio = Dio(BaseOptions(
    connectTimeout: AppConstants.connectionTimeout,
    receiveTimeout: const Duration(hours: 24),
  ));

  Stream<DownloadTask> addDownload({
    required String title,
    required String url,
    required String savePath,
    String? magnetUri,
    String? infoHash,
    int? downloadLimit,
    int? uploadLimit,
  }) {
    final id = 'task_${++_taskCounter}';
    final controller = StreamController<DownloadTask>.broadcast();
    _controllers[id] = controller;
    _cancelTokens[id] = CancelToken();

    final initial = DownloadTask(
      id: id,
      title: title,
      magnetUri: magnetUri,
      infoHash: infoHash,
      downloadUrl: _canResolveUrl(url) ? url : null,
      totalSize: 0,
      savePath: savePath,
      addedAt: DateTime.now(),
      status: DownloadStatus.queued,
      downloadLimit: downloadLimit,
      uploadLimit: uploadLimit,
    );
    _tasks.add(initial);
    controller.add(initial);

    if (_canResolveUrl(url)) {
      _startDownload(id, url, controller);
    } else {
      _updateTaskById(id, status: DownloadStatus.error);
      controller.add(_tasks.firstWhere((t) => t.id == id));
      appLogger.e('Cannot download: unsupported URL $url');
    }
    return controller.stream;
  }

  void _startDownload(String id, String url, StreamController<DownloadTask> controller, {bool isRetry = false}) {
    if (url.startsWith('magnet:')) {
      _startMagnetDownload(id, url, controller);
      return;
    }

    _updateTaskById(id, status: DownloadStatus.downloading, downloadedBytes: 0);
    _retryCounts.putIfAbsent(id, () => 0);

    int lastBytes = 0;
    DateTime lastTime = DateTime.now();
    final cancelToken = _cancelTokens[id];

    if (cancelToken == null) {
      controller.addError(Exception('Download cancelled'));
      return;
    }

    _ensureDirectory(savePathForId(id));

    _dio.download(
      url,
      savePathForId(id),
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (!controller.isClosed && total > 0) {
          final now = DateTime.now();
          final elapsed = now.difference(lastTime).inMilliseconds;
          int speed = 0;
          if (elapsed > 0) {
            speed = ((received - lastBytes) * 1000 ~/ elapsed).toInt();
          }
          lastBytes = received;
          lastTime = now;

          _updateTaskById(id,
            downloadedBytes: received,
            totalSize: total,
            progress: received / total,
            downloadSpeed: speed,
          );
          controller.add(_tasks.firstWhere((t) => t.id == id));
        }
      },
    ).then((_) {
      if (controller.isClosed) return;
      final idx = _tasks.indexWhere((t) => t.id == id);
      if (idx < 0) return;
      _updateTaskById(id,
        status: DownloadStatus.completed,
        progress: 1.0,
        downloadedBytes: _tasks[idx].totalSize,
        completedAt: DateTime.now(),
      );
      controller.add(_tasks[idx]);
      controller.close();
      _cleanup(id);
    }).catchError((error) {
      if (controller.isClosed) return;
      if (error is DioException && CancelToken.isCancel(error)) {
        _updateTaskById(id, status: DownloadStatus.paused);
        controller.add(_tasks.firstWhere((t) => t.id == id));
      } else if (!isRetry && _retryCounts[id]! < _maxRetries) {
        _retryCounts[id] = _retryCounts[id]! + 1;
        appLogger.w('Retrying download $id (attempt ${_retryCounts[id]})');
        _cancelTokens[id] = CancelToken();
        Future.delayed(const Duration(seconds: 5), () {
          _startDownload(id, url, controller, isRetry: true);
        });
      } else {
        _updateTaskById(id, status: DownloadStatus.error);
        controller.add(_tasks.firstWhere((t) => t.id == id));
        appLogger.e('Download $id failed', error: error);
      }
    });
  }

  bool _canResolveUrl(String url) {
    if (url.startsWith('magnet:')) return true;
    return url.startsWith('http://') || url.startsWith('https://') || url.startsWith('ftp://');
  }

  StreamSubscription<engine.TorrentStatus>? _engineSub;
  final Map<String, String> _activeEngineIds = {};
  final Map<String, StreamController<DownloadTask>> _engineTaskControllers = {};

  void _startMagnetDownload(String id, String url, StreamController<DownloadTask> controller) {
    _updateTaskById(id, status: DownloadStatus.downloading);
    final task = _tasks.firstWhere((t) => t.id == id);
    _ensureDirectory(task.savePath);

    final svc = TorrentService.instance;
    svc.addMagnet(url, name: task.title, savePath: task.savePath).then((torrentId) {
      _activeEngineIds[id] = torrentId;
      _engineTaskControllers[torrentId] = controller;
      _engineSub ??= svc.updates().listen(_handleEngineUpdate);
    }).catchError((error) {
      if (!controller.isClosed) {
        _updateTaskById(id, status: DownloadStatus.error);
        controller.add(_tasks.firstWhere((t) => t.id == id));
      }
    });
  }

  void _handleEngineUpdate(engine.TorrentStatus status) {
    final controller = _engineTaskControllers[status.id];
    if (controller == null) return;

    final taskId = _activeEngineIds.entries
      .firstWhere(
        (e) => e.value == status.id,
        orElse: () => const MapEntry('', ''),
      ).key;
    if (taskId.isEmpty) return;

    final engineState = status.state;
    DownloadStatus dlStatus;
    switch (engineState) {
      case engine.TorrentState.downloading:
        dlStatus = DownloadStatus.downloading;
        break;
      case engine.TorrentState.finished:
      case engine.TorrentState.seeding:
        dlStatus = DownloadStatus.completed;
        break;
      case engine.TorrentState.error:
        dlStatus = DownloadStatus.error;
        break;
      case engine.TorrentState.paused:
        dlStatus = DownloadStatus.paused;
        break;
      case engine.TorrentState.queued:
      case engine.TorrentState.checking:
        dlStatus = DownloadStatus.queued;
        break;
    }

    _updateTaskById(taskId,
      status: dlStatus,
      progress: status.progress,
      downloadedBytes: status.totalDownloaded,
      totalSize: status.totalSize,
      downloadSpeed: status.downloadRate,
      uploadSpeed: status.uploadRate,
      peers: status.peers,
      seeders: status.seeders,
    );

    if (!controller.isClosed) {
      final idx = _tasks.indexWhere((t) => t.id == taskId);
      if (idx >= 0) controller.add(_tasks[idx]);
    }

    if (dlStatus == DownloadStatus.completed || dlStatus == DownloadStatus.error) {
      _updateTaskById(taskId, completedAt: DateTime.now());
      _engineTaskControllers.remove(status.id);
      _cleanup(taskId);
    }
  }

  void _ensureDirectory(String path) {
    final dir = Directory(path).parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  String savePathForId(String id) {
    final idx = _tasks.indexWhere((t) => t.id == id);
    return idx >= 0 ? _tasks[idx].savePath : '/dev/null';
  }

  void pause(String taskId) {
    _cancelTokens[taskId]?.cancel();
    _updateTaskById(taskId, status: DownloadStatus.paused);
  }

  Stream<DownloadTask> resume(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx < 0) return const Stream.empty();

    final task = _tasks[idx];
    final url = task.downloadUrl;
    if (url == null || url.isEmpty || !_canResolveUrl(url)) {
      return Stream.error(Exception('Cannot resume: no valid download URL'));
    }

    final controller = StreamController<DownloadTask>.broadcast();
    _controllers[taskId] = controller;
    _cancelTokens[taskId] = CancelToken();

    _startDownload(taskId, url, controller);
    return controller.stream;
  }

  void remove(String taskId) {
    _cancelTokens[taskId]?.cancel();
    _tasks.removeWhere((t) => t.id == taskId);
    _retryCounts.remove(taskId);
    final engineId = _activeEngineIds.remove(taskId);
    if (engineId != null) {
      _engineTaskControllers.remove(engineId);
    }
    _cleanup(taskId);
  }

  Stream<DownloadTask> retry(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx < 0) return const Stream.empty();
    final task = _tasks[idx];

    final url = task.downloadUrl;
    if (url == null || url.isEmpty || !_canResolveUrl(url)) {
      return Stream.error(Exception('Cannot retry: no valid download URL'));
    }

    _retryCounts[taskId] = 0;
    final controller = StreamController<DownloadTask>.broadcast();
    _controllers[taskId] = controller;
    _cancelTokens[taskId] = CancelToken();
    _startDownload(taskId, url, controller, isRetry: true);
    return controller.stream;
  }

  List<DownloadTask> getTasks() => List.unmodifiable(_tasks);

  DownloadTask? getTask(String id) {
    final idx = _tasks.indexWhere((t) => t.id == id);
    return idx >= 0 ? _tasks[idx] : null;
  }

  void updatePriority(String taskId, DownloadPriority priority) {
    _updateTaskById(taskId, priority: priority);
  }

  void _updateTaskById(String id, {
    String? title,
    int? totalSize,
    int? downloadedBytes,
    int? uploadedBytes,
    DownloadStatus? status,
    double? progress,
    int? downloadSpeed,
    int? uploadSpeed,
    int? peers,
    int? seeders,
    DateTime? completedAt,
    Duration? eta,
    DownloadPriority? priority,
  }) {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final t = _tasks[idx];
    _tasks[idx] = t.copyWith(
      title: title,
      totalSize: totalSize,
      downloadedBytes: downloadedBytes,
      uploadedBytes: uploadedBytes,
      status: status,
      progress: progress,
      downloadSpeed: downloadSpeed,
      uploadSpeed: uploadSpeed,
      peers: peers,
      seeders: seeders,
      completedAt: completedAt,
      eta: eta,
      priority: priority,
    );
  }

  void _cleanup(String id) {
    _cancelTokens.remove(id);
    _controllers.remove(id);
  }

  void dispose() {
    _engineSub?.cancel();
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    for (final controller in _controllers.values) {
      controller.close();
    }
    _activeEngineIds.clear();
    _engineTaskControllers.clear();
    _cancelTokens.clear();
    _controllers.clear();
    _tasks.clear();
    _retryCounts.clear();
    TorrentService.instance.shutdown();
  }
}
