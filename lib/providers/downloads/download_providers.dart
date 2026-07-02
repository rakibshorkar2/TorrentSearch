import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/torrent.dart';
import '../../services/download_service.dart';
import '../../services/storage_service.dart';
import '../../logging/app_logger.dart';
import '../settings/settings_providers.dart';
import '../../services/background_download_service.dart';

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final service = DownloadService();
  ref.onDispose(() => service.dispose());
  return service;
});

final backgroundDownloadServiceProvider = Provider<BackgroundDownloadService>((ref) {
  final downloadService = ref.read(downloadServiceProvider);
  final service = BackgroundDownloadService(downloadService, ref);
  ref.onDispose(() => service.dispose());
  return service;
});

final downloadTasksProvider = StateNotifierProvider<DownloadTasksNotifier, List<DownloadTask>>((ref) {
  return DownloadTasksNotifier(
    ref.read(downloadServiceProvider),
    ref.read(storageServiceProvider),
  );
});

class DownloadTasksNotifier extends StateNotifier<List<DownloadTask>> {
  final DownloadService _service;
  final StorageService _storage;
  final Map<String, StreamSubscription<DownloadTask>> _subscriptions = {};

  DownloadTasksNotifier(this._service, this._storage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final tasks = await _storage.loadDownloads();
      if (!mounted) return;
      state = tasks;
    } catch (e) {
      appLogger.e('Failed to load downloads', error: e);
    }
  }

  Stream<DownloadTask> addDownload({
    required String title,
    required String url,
    required String savePath,
    String? magnetUri,
    String? infoHash,
    int? downloadLimit,
    int? uploadLimit,
  }) {
    final stream = _service.addDownload(
      title: title,
      url: url,
      savePath: savePath,
      magnetUri: magnetUri,
      infoHash: infoHash,
      downloadLimit: downloadLimit,
      uploadLimit: uploadLimit,
    );
    _listenToStream(stream);
    return stream;
  }

  void _listenToStream(Stream<DownloadTask> stream) {
    StreamSubscription<DownloadTask>? sub;
    sub = stream.listen(
      (task) {
        final idx = state.indexWhere((t) => t.id == task.id);
        if (idx >= 0) {
          state = [...state];
          state[idx] = task;
        } else {
          state = [...state, task];
        }
      },
      onError: (e) {
        appLogger.e('Download stream error', error: e);
      },
      onDone: () {
        _persist();
        if (sub != null) {
          _subscriptions.remove(sub.hashCode.toString());
        }
      },
    );
    _subscriptions[sub.hashCode.toString()] = sub;
  }

  void updateTask(DownloadTask updated) {
    state = state.map((t) => t.id == updated.id ? updated : t).toList();
    _persist();
  }

  void removeTask(String id) {
    _service.remove(id);
    state = state.where((t) => t.id != id).toList();
    _persist();
  }

  void pauseTask(String id) {
    _service.pause(id);
    state = state.map((t) {
      if (t.id == id) return t.copyWith(status: DownloadStatus.paused);
      return t;
    }).toList();
    _persist();
  }

  void resumeTask(String id) {
    final stream = _service.resume(id);
    _listenToStream(stream);
    state = state.map((t) {
      if (t.id == id) return t.copyWith(status: DownloadStatus.downloading);
      return t;
    }).toList();
    _persist();
  }

  void pauseAll() {
    for (final task in state) {
      if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.queued) {
        pauseTask(task.id);
      }
    }
  }

  void resumeAll() {
    for (final task in state) {
      if (task.status == DownloadStatus.paused) {
        resumeTask(task.id);
      }
    }
  }

  void removeCompleted() {
    final toRemove = state.where((t) => t.status == DownloadStatus.completed).map((t) => t.id).toList();
    for (final id in toRemove) {
      _service.remove(id);
    }
    state = state.where((t) => !toRemove.contains(t.id)).toList();
    _persist();
  }

  void moveTask(int oldIndex, int newIndex) {
    final list = [...state];
    final task = list.removeAt(oldIndex);
    list.insert(newIndex, task);
    state = list;
    _persist();
  }

  void retryTask(String id) {
    final idx = state.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final stream = _service.retry(id);
    _listenToStream(stream);
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == idx)
          state[i].copyWith(status: DownloadStatus.queued)
        else
          state[i],
    ];
  }

  Future<void> _persist() async {
    try {
      await _storage.saveDownloads(state);
    } catch (e) {
      appLogger.e('Failed to persist downloads', error: e);
    }
  }

  @override
  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}

final downloadStatsProvider = Provider<DownloadStats>((ref) {
  final tasks = ref.watch(downloadTasksProvider);
  return DownloadStats(tasks);
});

class DownloadStats {
  final int active;
  final int paused;
  final int completed;
  final int error;
  final int total;

  DownloadStats(List<DownloadTask> tasks) :
    active = tasks.where((t) => t.status == DownloadStatus.downloading || t.status == DownloadStatus.queued).length,
    paused = tasks.where((t) => t.status == DownloadStatus.paused || t.status == DownloadStatus.stopped).length,
    completed = tasks.where((t) => t.status == DownloadStatus.completed).length,
    error = tasks.where((t) => t.status == DownloadStatus.error).length,
    total = tasks.length;
}
