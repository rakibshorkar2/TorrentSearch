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
    final task = _tasks.firstWhere((t) => t.id == id);
    _updateTask(task.copyWith(status: DownloadStatus.downloading));

    _dio.download(
      url,
      task.savePath,
      cancelToken: _cancelTokens[id],
      onReceiveProgress: (received, total) {
        if (total > 0) {
          final updated = task.copyWith(
            downloadedBytes: received,
            totalSize: total,
            progress: received / total,
            downloadSpeed: _calculateSpeed(received, id),
          );
          _updateTask(updated);
          controller.add(updated);
        }
      },
    ).then((_) {
      final completed = _tasks.firstWhere((t) => t.id == id);
      _updateTask(completed.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        downloadedBytes: completed.totalSize,
        completedAt: DateTime.now(),
      ));
      controller.add(completed.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        downloadedBytes: completed.totalSize,
        completedAt: DateTime.now(),
      ));
      controller.close();
      _cleanup(id);
    }).catchError((error) {
      if (error is DioException && CancelToken.isCancel(error)) {
        _updateTask(task.copyWith(status: DownloadStatus.paused));
        controller.add(task.copyWith(status: DownloadStatus.paused));
      } else {
        _updateTask(task.copyWith(status: DownloadStatus.error));
        controller.add(task.copyWith(status: DownloadStatus.error));
      }
    });
  }

  void pause(String taskId) {
    _cancelTokens[taskId]?.cancel();
    final task = _tasks.firstWhere((t) => t.id == taskId);
    _updateTask(task.copyWith(status: DownloadStatus.paused));
  }

  Stream<DownloadTask> resume(String taskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final controller = StreamController<DownloadTask>.broadcast();
    _controllers[taskId] = controller;
    _cancelTokens[taskId] = CancelToken();
    _startDownload(taskId, task.magnetUri ?? task.torrentPath ?? '', controller);
    return controller.stream;
  }

  void remove(String taskId) {
    _cancelTokens[taskId]?.cancel();
    _tasks.removeWhere((t) => t.id == taskId);
    _cleanup(taskId);
  }

  List<DownloadTask> getTasks() => List.unmodifiable(_tasks);

  DownloadTask? getTask(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  int _calculateSpeed(int received, String id) {
    // Simplified speed calculation
    final task = _tasks.firstWhere((t) => t.id == id, orElse: () => DownloadTask(id: '', title: '', totalSize: 0, savePath: '', addedAt: DateTime.now()));
    if (task.downloadedBytes > 0 && received > task.downloadedBytes) {
      return received - task.downloadedBytes;
    }
    return 0;
  }

  void _updateTask(DownloadTask updated) {
    final index = _tasks.indexWhere((t) => t.id == updated.id);
    if (index >= 0) {
      _tasks[index] = updated;
    }
  }

  void _cleanup(String id) {
    _cancelTokens.remove(id);
    _controllers.remove(id);
  }
}
