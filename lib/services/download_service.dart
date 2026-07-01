import 'dart:async';
import 'package:dio/dio.dart';
import '../models/torrent.dart';
import '../core/constants/app_constants.dart';

class DownloadService {
  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, StreamController<DownloadTask>> _controllers = {};
  final List<DownloadTask> _tasks = [];
  int _taskCounter = 0;

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
      totalSize: 0,
      savePath: savePath,
      addedAt: DateTime.now(),
      status: DownloadStatus.queued,
    );
    _tasks.add(initial);
    controller.add(initial);

    _startDownload(id, url, controller);
    return controller.stream;
  }

  void _startDownload(String id, String url, StreamController<DownloadTask> controller) {
    if (!_canResolveUrl(url)) {
      controller.addError(Exception('Cannot download: invalid URL $url'));
      _cleanup(id);
      return;
    }

    _updateTaskById(id, status: DownloadStatus.downloading, downloadedBytes: 0);

    int lastBytes = 0;
    DateTime lastTime = DateTime.now();

    _dio.download(
      url,
      _resolvePath(id),
      cancelToken: _cancelTokens[id],
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
      } else {
        _updateTaskById(id, status: DownloadStatus.error);
        controller.add(_tasks.firstWhere((t) => t.id == id));
      }
    });
  }

  bool _canResolveUrl(String url) {
    if (url.startsWith('magnet:') || url.startsWith('torrent:')) return false;
    return url.startsWith('http://') || url.startsWith('https://') || url.startsWith('ftp://');
  }

  String _resolvePath(String id) {
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
    final controller = StreamController<DownloadTask>.broadcast();
    _controllers[taskId] = controller;
    _cancelTokens[taskId] = CancelToken();

    final url = task.magnetUri?.isNotEmpty == true
        ? task.magnetUri!
        : task.torrentPath?.isNotEmpty == true
            ? task.torrentPath!
            : '';

    if (!_canResolveUrl(url)) {
      controller.addError(Exception('Cannot resume download: no valid URL'));
      return controller.stream;
    }

    _startDownload(taskId, url, controller);
    return controller.stream;
  }

  void remove(String taskId) {
    _cancelTokens[taskId]?.cancel();
    _tasks.removeWhere((t) => t.id == taskId);
    _cleanup(taskId);
  }

  List<DownloadTask> getTasks() => List.unmodifiable(_tasks);

  DownloadTask? getTask(String id) {
    final idx = _tasks.indexWhere((t) => t.id == id);
    return idx >= 0 ? _tasks[idx] : null;
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
    );
  }

  void _cleanup(String id) {
    _cancelTokens.remove(id);
    _controllers.remove(id);
  }

  void dispose() {
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    for (final controller in _controllers.values) {
      controller.close();
    }
    _cancelTokens.clear();
    _controllers.clear();
    _tasks.clear();
  }
}
