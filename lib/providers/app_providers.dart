import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../models/torrent.dart';
import '../models/search_result.dart';
import '../services/torrent_search_service.dart';
import '../services/seedr_service.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';
import '../services/background_download_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

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

final torrentSearchServiceProvider = Provider<TorrentSearchService>((ref) {
  return TorrentSearchService();
});

final seedrServiceProvider = Provider<SeedrService>((ref) {
  return SeedrService();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.read(storageServiceProvider));
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storage;

  SettingsNotifier(this._storage) : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final settings = await _storage.loadSettings();
    if (!mounted) return;
    state = settings;
  }

  Future<void> update(AppSettings updated) async {
    state = updated;
    await _storage.saveSettings(updated);
  }
}

final downloadTasksProvider = StateNotifierProvider<DownloadTasksNotifier, List<DownloadTask>>((ref) {
  return DownloadTasksNotifier(ref.read(downloadServiceProvider), ref.read(storageServiceProvider));
});

class DownloadTasksNotifier extends StateNotifier<List<DownloadTask>> {
  final DownloadService _service;
  final StorageService _storage;
  final Map<String, StreamSubscription<DownloadTask>> _subscriptions = {};

  DownloadTasksNotifier(this._service, this._storage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final tasks = await _storage.loadDownloads();
    if (!mounted) return;
    state = tasks;
  }

  Stream<DownloadTask> addDownload({
    required String title,
    required String url,
    required String savePath,
    String? magnetUri,
    String? infoHash,
  }) {
    final stream = _service.addDownload(
      title: title,
      url: url,
      savePath: savePath,
      magnetUri: magnetUri,
      infoHash: infoHash,
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
      onError: (_) {},
      onDone: () {
        _persist();
        if (sub != null) _subscriptions.remove(sub.hashCode.toString());
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

  Future<void> _persist() async {
    await _storage.saveDownloads(state);
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

final searchResultProvider = StateNotifierProvider<SearchResultNotifier, SearchResult>((ref) {
  return SearchResultNotifier(ref.read(torrentSearchServiceProvider));
});

class SearchResultNotifier extends StateNotifier<SearchResult> {
  final TorrentSearchService _service;
  bool _disposed = false;

  SearchResultNotifier(this._service) : super(const SearchResult());

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> search(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _service.search(query);
      if (_disposed) return;
      state = SearchResult(results: results, hasMore: results.length >= 100);
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadTop() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _service.getTopTorrents();
      if (_disposed) return;
      state = SearchResult(results: results, hasMore: false);
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const SearchResult();
  }
}

final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier(ref.read(storageServiceProvider));
});

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  final StorageService _storage;

  SearchHistoryNotifier(this._storage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final history = await _storage.loadSearchHistory();
    if (!mounted) return;
    state = history;
  }

  Future<void> addQuery(String query) async {
    await _storage.addSearchQuery(query);
    state = await _storage.loadSearchHistory();
  }

  Future<void> clear() async {
    await _storage.saveSearchHistory([]);
    state = [];
  }
}
