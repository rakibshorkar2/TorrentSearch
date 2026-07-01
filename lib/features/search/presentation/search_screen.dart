import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/torrent.dart';
import '../../../providers/app_providers.dart';
import '../../../models/search_result.dart';
import '../../downloads/presentation/add_download_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final searchResult = ref.watch(searchResultProvider);
    final history = ref.watch(searchHistoryProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Search', style: TorrentFlowTheme.headline.copyWith(
          color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
        )),
        backgroundColor: isDark
            ? TorrentFlowTheme.darkSurface.withValues(alpha: 0.85)
            : TorrentFlowTheme.lightSurface.withValues(alpha: 0.85),
        border: Border(bottom: BorderSide(
          color: isDark ? TorrentFlowTheme.darkSeparator : TorrentFlowTheme.lightSeparator,
          width: 0.5,
        )),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SearchField(
                      controller: _searchController,
                      onSubmitted: _performSearch,
                      onClear: _clearSearch,
                      isSearching: _isSearching,
                    ),
                    const SizedBox(height: TorrentFlowTheme.spacing),
                  ],
                ),
              ),
            ),
            if (_isSearching) ..._buildSearchResults(searchResult, isDark)
            else ..._buildHistory(history, isDark),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSearchResults(SearchResult result, bool isDark) {
    if (result.isLoading) {
      return [
        const SliverFillRemaining(
          child: Center(child: CupertinoActivityIndicator()),
        ),
      ];
    }

    if (result.error != null) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.exclamationmark_triangle,
                    size: 48, color: TorrentFlowTheme.warning),
                  const SizedBox(height: 12),
                  Text(result.error!, style: TorrentFlowTheme.body.copyWith(
                    color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                  ), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    if (result.results.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
            child: Text('No results found',
              style: TorrentFlowTheme.body.copyWith(
                color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
              )),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final torrent = result.results[index];
              return _TorrentResultCard(
                torrent: torrent,
                isDark: isDark,
                onTap: () => _showTorrentOptions(torrent),
              );
            },
            childCount: result.results.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildHistory(List<String> history, bool isDark) {
    if (history.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.search, size: 48,
                  color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
                const SizedBox(height: 12),
                Text('Search for torrents', style: TorrentFlowTheme.body.copyWith(
                  color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                )),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(
            left: TorrentFlowTheme.standardPadding,
            right: TorrentFlowTheme.standardPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Searches', style: TorrentFlowTheme.footnote.copyWith(
                color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              )),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text('Clear', style: TorrentFlowTheme.footnote.copyWith(color: TorrentFlowTheme.accent)),
                onPressed: () => ref.read(searchHistoryProvider.notifier).clear(),
              ),
            ],
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final query = history[index];
            return CupertinoButton(
              padding: const EdgeInsets.symmetric(
                horizontal: TorrentFlowTheme.standardPadding,
                vertical: 10,
              ),
              onPressed: () {
                _searchController.text = query;
                _performSearch(query);
              },
              child: Row(
                children: [
                  Icon(CupertinoIcons.clock, size: 18,
                    color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(query, style: TorrentFlowTheme.body.copyWith(
                      color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                    )),
                  ),
                ],
              ),
            );
          },
          childCount: history.length,
        ),
      ),
    ];
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    ref.read(searchHistoryProvider.notifier).addQuery(query.trim());
    ref.read(searchResultProvider.notifier).search(query.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _isSearching = false);
    ref.read(searchResultProvider.notifier).clear();
  }

  void _showTorrentOptions(TorrentInfo torrent) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => AddDownloadSheet(torrent: torrent),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final bool isSearching;

  const _SearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? TorrentFlowTheme.darkSurface2 : TorrentFlowTheme.lightSurface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: 'Search torrents...',
        placeholderStyle: TorrentFlowTheme.body.copyWith(
          color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
        ),
        style: TorrentFlowTheme.body.copyWith(
          color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
        ),
        padding: const EdgeInsets.all(14),
        clearButtonMode: OverlayVisibilityMode.editing,
        onSubmitted: onSubmitted,
        suffix: isSearching
            ? CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: onClear,
                child: Icon(CupertinoIcons.xmark_circle_fill, size: 20,
                  color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
              )
            : null,
        decoration: null,
      ),
    );
  }
}

class _TorrentResultCard extends StatelessWidget {
  final TorrentInfo torrent;
  final bool isDark;
  final VoidCallback onTap;

  const _TorrentResultCard({
    required this.torrent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TorrentFlowTheme.spacing),
      child: GlassCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(torrent.title, style: TorrentFlowTheme.callout.copyWith(
              color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
              fontWeight: FontWeight.w500,
            ), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoChip(label: torrent.formattedSize),
                const SizedBox(width: 6),
                _InfoChip(label: '${torrent.seeders} S', icon: CupertinoIcons.arrow_up_circle),
                const SizedBox(width: 6),
                _InfoChip(label: '${torrent.leechers} L', icon: CupertinoIcons.arrow_down_circle),
                const SizedBox(width: 6),
                HealthIndicator(seeders: torrent.seeders, leechers: torrent.leechers),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _InfoChip({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? TorrentFlowTheme.darkSurface3 : TorrentFlowTheme.lightSurface2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: TorrentFlowTheme.darkTextSecondary),
            const SizedBox(width: 3),
          ],
          Text(label, style: TorrentFlowTheme.caption1.copyWith(
            color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
          )),
        ],
      ),
    );
  }
}
