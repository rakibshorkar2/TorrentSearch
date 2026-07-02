import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/torrent.dart';
import '../../models/search_result.dart';
import '../../services/search/torrent_search_service.dart';
import '../../services/storage_service.dart';
import '../../logging/app_logger.dart';
import '../settings/settings_providers.dart';

final torrentSearchServiceProvider = Provider<TorrentSearchService>((ref) {
  return TorrentSearchService();
});

final searchResultProvider = StateNotifierProvider<SearchResultNotifier, SearchResult>((ref) {
  return SearchResultNotifier(ref.read(torrentSearchServiceProvider));
});

class SearchResultNotifier extends StateNotifier<SearchResult> {
  final TorrentSearchService _service;
  bool _disposed = false;
  Timer? _debounce;

  SearchResultNotifier(this._service) : super(const SearchResult());

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }

  void searchDebounced(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      search(query);
    });
  }

  Future<void> search(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _service.searchAll(query);
      if (_disposed) return;
      state = SearchResult(results: results, hasMore: results.length >= 100);
    } catch (e) {
      if (_disposed) return;
      appLogger.e('Search failed', error: e);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> searchWithFilters(String query, {
    String? category,
    String? source,
    String? minQuality,
    int? minSeeders,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _service.searchWithFilters(
        query,
        category: category,
        source: source,
        minQuality: minQuality,
        minSeeders: minSeeders,
      );
      if (_disposed) return;
      state = SearchResult(results: results, hasMore: false);
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void sortResults(SearchSort sort) {
    final sorted = List<TorrentInfo>.from(state.results);
    switch (sort) {
      case SearchSort.seedersDesc:
        sorted.sort((a, b) => b.seeders.compareTo(a.seeders));
      case SearchSort.seedersAsc:
        sorted.sort((a, b) => a.seeders.compareTo(b.seeders));
      case SearchSort.sizeDesc:
        sorted.sort((a, b) => b.size.compareTo(a.size));
      case SearchSort.sizeAsc:
        sorted.sort((a, b) => a.size.compareTo(b.size));
      case SearchSort.nameAsc:
        sorted.sort((a, b) => a.title.compareTo(b.title));
      case SearchSort.nameDesc:
        sorted.sort((a, b) => b.title.compareTo(a.title));
      case SearchSort.dateDesc:
        sorted.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      case SearchSort.dateAsc:
        sorted.sort((a, b) => a.uploadDate.compareTo(b.uploadDate));
    }
    state = state.copyWith(results: sorted);
  }

  void filterByCategory(String? category) {
    if (category == null || category == 'All') {
      return;
    }
    final filtered = state.results.where((t) =>
      t.category?.toLowerCase() == category.toLowerCase()).toList();
    state = state.copyWith(results: filtered);
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
    try {
      final history = await _storage.loadSearchHistory();
      if (!mounted) return;
      state = history;
    } catch (e) {
      appLogger.e('Failed to load search history', error: e);
    }
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

enum SearchSort {
  seedersDesc,
  seedersAsc,
  sizeDesc,
  sizeAsc,
  nameAsc,
  nameDesc,
  dateDesc,
  dateAsc,
}
