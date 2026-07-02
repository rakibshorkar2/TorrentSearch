import 'torrent.dart';

class SearchResult {
  final List<TorrentInfo> results;
  final bool hasMore;
  final String? error;
  final bool isLoading;
  final String? activeSource;
  final String? activeCategory;

  const SearchResult({
    this.results = const [],
    this.hasMore = false,
    this.error,
    this.isLoading = false,
    this.activeSource,
    this.activeCategory,
  });

  SearchResult copyWith({
    List<TorrentInfo>? results,
    bool? hasMore,
    String? error,
    bool? isLoading,
    String? activeSource,
    String? activeCategory,
  }) {
    return SearchResult(
      results: results ?? this.results,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      isLoading: isLoading ?? this.isLoading,
      activeSource: activeSource ?? this.activeSource,
      activeCategory: activeCategory ?? this.activeCategory,
    );
  }
}
