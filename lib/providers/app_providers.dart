import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../models/torrent.dart';
import '../models/search_result.dart';
import '../services/torrent_search_service.dart';
import '../services/seedr_service.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  final service = StorageService();
  ref.onDispose(() {});
  return service;
});

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService();
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

  DownloadTasksNotifier(this._service, this._storage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final tasks = await _storage.loadDownloads();
    state = tasks;
  }

  void addTask(DownloadTask task) {
    state = [...state, task];
    _persist();
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
    _service.resume(id);
    state = state.map((t) {
      if (t.id == id) return t.copyWith(status: DownloadStatus.downloading);
      return t;
    }).toList();
    _persist();
  }

  Future<void> _persist() async {
    await _storage.saveDownloads(state);
  }
}

final searchResultProvider = StateNotifierProvider<SearchResultNotifier, SearchResult>((ref) {
  return SearchResultNotifier(ref.read(torrentSearchServiceProvider));
});

class SearchResultNotifier extends StateNotifier<SearchResult> {
  final TorrentSearchService _service;

  SearchResultNotifier(this._service) : super(const SearchResult());

  Future<void> search(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _service.search(query);
      state = SearchResult(results: results, hasMore: results.length >= 100);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadTop() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _service.getTopTorrents();
      state = SearchResult(results: results, hasMore: false);
    } catch (e) {
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
    state = await _storage.loadSearchHistory();
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
