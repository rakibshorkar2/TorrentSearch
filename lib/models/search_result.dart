import 'torrent.dart';

class SearchResult {
  final List<TorrentInfo> results;
  final bool hasMore;
  final String? error;
  final bool isLoading;

  const SearchResult({
    this.results = const [],
    this.hasMore = false,
    this.error,
    this.isLoading = false,
  });

  SearchResult copyWith({
    List<TorrentInfo>? results,
    bool? hasMore,
    String? error,
    bool? isLoading,
  }) {
    return SearchResult(
      results: results ?? this.results,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
