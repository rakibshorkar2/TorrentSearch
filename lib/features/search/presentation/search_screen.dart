import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/torrent.dart';
import '../../../providers/search/search_providers.dart';
import '../../../providers/history/history_providers.dart';
import '../../../models/search_result.dart';
import '../../downloads/presentation/add_download_sheet.dart';
import '../../../providers/seedr/seedr_providers.dart';
import '../../../providers/downloads/download_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String? _selectedCategory;
  String? _selectedSource;
  String? _selectedSortBy;
  int _minSeeders = 0;
  final Set<String> _selectedTorrents = {};
  bool _selectionMode = false;

  final _categories = ['All', 'Movies', 'TV', 'Music', 'Games', 'Apps'];
  final _sources = ['All', 'The Pirate Bay', 'EZTV', 'Nyaa.si', 'YTS', '1337x'];
  final _sortOptions = [
    'Seeders (High-Low)',
    'Seeders (Low-High)',
    'Size (High-Low)',
    'Size (Low-High)',
    'Name (A-Z)',
    'Name (Z-A)',
    'Date (Newest)',
    'Date (Oldest)',
  ];

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
        trailing: _isSearching && searchResult.results.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _selectionMode = !_selectionMode),
                child: Icon(
                  _selectionMode ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.checkmark_circle,
                  color: TorrentFlowTheme.accent,
                ),
              )
            : null,
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
                    if (_isSearching) _buildFilterChips(isDark),
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

  Widget _buildFilterChips(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Categories',
                icon: CupertinoIcons.tray_full,
                isActive: _selectedCategory != null,
                isDark: isDark,
                onTap: () => _showCategoryPicker(isDark),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Source',
                icon: CupertinoIcons.globe,
                isActive: _selectedSource != null,
                isDark: isDark,
                onTap: () => _showSourcePicker(isDark),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Sort',
                icon: CupertinoIcons.arrow_up_arrow_down,
                isActive: _selectedSortBy != null,
                isDark: isDark,
                onTap: () => _showSortPicker(isDark),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Min Seeds',
                icon: CupertinoIcons.sort_down_circle,
                isActive: _minSeeders > 0,
                isDark: isDark,
                onTap: () => _showMinSeedPicker(isDark),
              ),
            ],
          ),
        ),
        if (_selectedCategory != null || _selectedSource != null || _selectedSortBy != null || _minSeeders > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              onPressed: _clearFilters,
              child: const Text('Clear Filters', style: TextStyle(fontSize: 13)),
            ),
          ),
      ],
    );
  }

  void _showCategoryPicker(bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _buildPickerSheet(
        title: 'Category',
        items: _categories,
        selected: _selectedCategory,
        onSelected: (val) {
          setState(() => _selectedCategory = val == 'All' ? null : val);
          _applyFilters();
        },
        isDark: isDark,
      ),
    );
  }

  void _showSourcePicker(bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _buildPickerSheet(
        title: 'Source',
        items: _sources,
        selected: _selectedSource,
        onSelected: (val) {
          setState(() => _selectedSource = val == 'All' ? null : val);
          _applyFilters();
        },
        isDark: isDark,
      ),
    );
  }

  void _showSortPicker(bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _buildPickerSheet(
        title: 'Sort By',
        items: _sortOptions,
        selected: _selectedSortBy,
        onSelected: (val) {
          setState(() => _selectedSortBy = val);
          _applyFilters();
        },
        isDark: isDark,
      ),
    );
  }

  void _showMinSeedPicker(bool isDark) {
    final controller = TextEditingController(text: '$_minSeeders');
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Minimum Seeders'),
        content: CupertinoTextField(
          controller: controller,
          placeholder: '0',
          keyboardType: TextInputType.number,
        ),
        actions: [
          CupertinoButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoButton(
            child: const Text('Apply'),
            onPressed: () {
              setState(() => _minSeeders = int.tryParse(controller.text) ?? 0);
              _applyFilters();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPickerSheet({
    required String title,
    required List<String> items,
    required String? selected,
    required ValueChanged<String> onSelected,
    required bool isDark,
  }) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: isDark ? TorrentFlowTheme.darkSurface : TorrentFlowTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(title, style: TorrentFlowTheme.headline),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final isSelected = item == selected || (selected == null && i == 0);
                return CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  onPressed: () {
                    onSelected(item);
                    Navigator.of(context).pop();
                  },
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                        color: isSelected ? TorrentFlowTheme.accent : TorrentFlowTheme.darkTextSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(item, style: TorrentFlowTheme.body.copyWith(
                        color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                      )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedSource = null;
      _selectedSortBy = null;
      _minSeeders = 0;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final searchNotifier = ref.read(searchResultProvider.notifier);

    if (_selectedCategory != null || _selectedSource != null || _minSeeders > 0) {
      searchNotifier.searchWithFilters(
        query,
        category: _selectedCategory,
        source: _selectedSource,
        minSeeders: _minSeeders,
      );
    }

    if (_selectedSortBy != null) {
      final sort = _sortOptionToEnum(_selectedSortBy!);
      if (sort != null) searchNotifier.sortResults(sort);
    }
  }

  SearchSort? _sortOptionToEnum(String option) {
    switch (option) {
      case 'Seeders (High-Low)': return SearchSort.seedersDesc;
      case 'Seeders (Low-High)': return SearchSort.seedersAsc;
      case 'Size (High-Low)': return SearchSort.sizeDesc;
      case 'Size (Low-High)': return SearchSort.sizeAsc;
      case 'Name (A-Z)': return SearchSort.nameAsc;
      case 'Name (Z-A)': return SearchSort.nameDesc;
      case 'Date (Newest)': return SearchSort.dateDesc;
      case 'Date (Oldest)': return SearchSort.dateAsc;
      default: return null;
    }
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
                  Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: TorrentFlowTheme.warning),
                  const SizedBox(height: 12),
                  Text(result.error!, style: TorrentFlowTheme.body.copyWith(
                    color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                  ), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    onPressed: () => _performSearch(_searchController.text),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    if (result.results.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.search, size: 48,
                  color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
                const SizedBox(height: 12),
                Text('No results found', style: TorrentFlowTheme.body.copyWith(
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
          padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
          child: Text('${result.results.length} results',
            style: TorrentFlowTheme.footnote.copyWith(
              color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
            )),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final torrent = result.results[index];
              final isSelected = _selectedTorrents.contains(torrent.id);
              return _TorrentResultCard(
                torrent: torrent,
                isDark: isDark,
                selectionMode: _selectionMode,
                isSelected: isSelected,
                onTap: () {
                  if (_selectionMode) {
                    setState(() {
                      if (isSelected) {
                        _selectedTorrents.remove(torrent.id);
                      } else {
                        _selectedTorrents.add(torrent.id);
                      }
                    });
                  } else {
                    _showTorrentOptions(torrent);
                  }
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _selectionMode = true;
                    _selectedTorrents.add(torrent.id);
                  });
                },
                onMagnetCopy: () {
                  if (torrent.magnetUri != null) {
                    Clipboard.setData(ClipboardData(text: torrent.magnetUri!));
                    HapticFeedback.lightImpact();
                    ref.read(historyProvider.notifier).addMagnetLink(
                      title: torrent.title,
                      magnetUri: torrent.magnetUri!,
                      infoHash: torrent.infoHash,
                      totalSize: torrent.size,
                    );
                    _showToast('Magnet link copied');
                  }
                },
                onSendToSeedr: () => _sendToSeedr(torrent),
                onDownload: torrent.fileUrl?.isNotEmpty == true
                    ? () => _startDownload(torrent)
                    : () => _sendToSeedr(torrent),
              );
            },
            childCount: result.results.length,
          ),
        ),
      ),
      if (_selectionMode)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    onPressed: _selectedTorrents.isEmpty ? null : () => _batchAddDownloads(result),
                    child: Text('Download (${_selectedTorrents.length})'),
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  onPressed: _selectedTorrents.isEmpty ? null : () => _batchSendToSeedr(result),
                  child: const Icon(CupertinoIcons.cloud),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  void _batchAddDownloads(SearchResult result) async {
    final notifier = ref.read(downloadTasksProvider.notifier);
    final docsDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${docsDir.path}/Downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    int added = 0;
    for (final torrent in result.results) {
      if (_selectedTorrents.contains(torrent.id)) {
        final url = torrent.fileUrl;
        if (url == null || url.isEmpty) continue;
        final safeName = torrent.title.replaceAll(RegExp(r'[^\w\s\-.]'), '').trim();
        final savePath = '${downloadsDir.path}/${safeName.isNotEmpty ? safeName : 'download'}';
        notifier.addDownload(
          title: torrent.title,
          url: url,
          savePath: savePath,
          magnetUri: torrent.magnetUri,
          infoHash: torrent.infoHash,
        );
        added++;
      }
    }
    setState(() {
      _selectionMode = false;
      _selectedTorrents.clear();
    });
    _showToast('$added downloads started');
  }

  void _batchSendToSeedr(SearchResult result) async {
    try {
      final seedrService = ref.read(seedrServiceProvider);
      for (final torrent in result.results) {
        if (_selectedTorrents.contains(torrent.id) && torrent.magnetUri != null) {
          await seedrService.addMagnet(torrent.magnetUri!);
        }
      }
      setState(() {
        _selectionMode = false;
        _selectedTorrents.clear();
      });
      _showToast('Sent to Seedr');
    } catch (e) {
      _showToast('Error: $e');
    }
  }

  void _sendToSeedr(TorrentInfo torrent) async {
    if (torrent.magnetUri == null) return;
    try {
      final seedrService = ref.read(seedrServiceProvider);
      await seedrService.addMagnet(torrent.magnetUri!);
      _showToast('Added to Seedr');
    } catch (e) {
      _showToast('Error: $e');
    }
  }

  Future<void> _startDownload(TorrentInfo torrent) async {
    final url = torrent.fileUrl;
    if (url == null || url.isEmpty) return;
    HapticFeedback.mediumImpact();
    try {
      final notifier = ref.read(downloadTasksProvider.notifier);
      final docsDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${docsDir.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final safeName = torrent.title.replaceAll(RegExp(r'[^\w\s\-.]'), '').trim();
      final savePath = '${downloadsDir.path}/${safeName.isNotEmpty ? safeName : 'download'}';
      await notifier.addDownload(
        title: torrent.title,
        url: url,
        savePath: savePath,
        magnetUri: torrent.magnetUri,
        infoHash: torrent.infoHash,
      ).first;
      ref.read(historyProvider.notifier).addDownload(
        title: torrent.title,
        magnetUri: url,
        infoHash: torrent.infoHash,
        totalSize: torrent.size,
      );
      _showToast('Download started');
    } catch (e) {
      _showToast('Error: $e');
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Icon(CupertinoIcons.checkmark_circle, color: TorrentFlowTheme.success, size: 40),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message, textAlign: TextAlign.center),
        ),
        actions: [
          CupertinoButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
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
                const SizedBox(height: 8),
                Text('Multi-source: TPB, 1337x, YTS, EZTV, Nyaa.si',
                  style: TorrentFlowTheme.footnote.copyWith(
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
                  Icon(CupertinoIcons.chevron_forward, size: 14,
                    color: TorrentFlowTheme.darkTextSecondary),
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
    HapticFeedback.lightImpact();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _selectionMode = false;
      _selectedTorrents.clear();
    });
    ref.read(searchResultProvider.notifier).clear();
  }

  void _showTorrentOptions(TorrentInfo torrent) {
    HapticFeedback.mediumImpact();
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
        placeholder: 'Search torrents across 5 sources...',
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

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? TorrentFlowTheme.accent.withValues(alpha: 0.15)
              : (isDark ? TorrentFlowTheme.darkSurface3 : TorrentFlowTheme.lightSurface2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? TorrentFlowTheme.accent.withValues(alpha: 0.5) : CupertinoColors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
              color: isActive ? TorrentFlowTheme.accent : TorrentFlowTheme.darkTextSecondary),
            const SizedBox(width: 6),
            Text(label, style: TorrentFlowTheme.caption1.copyWith(
              color: isActive ? TorrentFlowTheme.accent : (isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            )),
          ],
        ),
      ),
    );
  }
}

class _TorrentResultCard extends StatelessWidget {
  final TorrentInfo torrent;
  final bool isDark;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMagnetCopy;
  final VoidCallback? onSendToSeedr;
  final VoidCallback? onDownload;

  const _TorrentResultCard({
    required this.torrent,
    required this.isDark,
    this.selectionMode = false,
    this.isSelected = false,
    required this.onTap,
    this.onLongPress,
    this.onMagnetCopy,
    this.onSendToSeedr,
    this.onDownload,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                      color: isSelected ? TorrentFlowTheme.accent : TorrentFlowTheme.darkTextSecondary,
                      size: 22,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(torrent.title, style: TorrentFlowTheme.callout.copyWith(
                        color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                        fontWeight: FontWeight.w500,
                      ), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (torrent.source != null) ...[
                            _MiniBadge(label: torrent.source!, color: TorrentFlowTheme.accent),
                            const SizedBox(width: 4),
                          ],
                          if (torrent.quality != null) ...[
                            _MiniBadge(label: torrent.quality!, color: TorrentFlowTheme.success),
                            const SizedBox(width: 4),
                          ],
                          if (torrent.isVideo)
                            _MiniBadge(label: 'Video', color: TorrentFlowTheme.accentLight),
                          if (torrent.isAudio)
                            _MiniBadge(label: 'Audio', color: TorrentFlowTheme.warning),
                          if (torrent.isGame)
                            _MiniBadge(label: 'Game', color: TorrentFlowTheme.success),
                          if (torrent.isApp)
                            _MiniBadge(label: 'App', color: TorrentFlowTheme.accent),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                const Spacer(),
                if (onMagnetCopy != null)
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    onPressed: onMagnetCopy,
                    child: Icon(CupertinoIcons.link, size: 16, color: TorrentFlowTheme.darkTextSecondary),
                  ),
                if (onSendToSeedr != null)
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    onPressed: onSendToSeedr,
                    child: Icon(CupertinoIcons.cloud_upload, size: 16, color: TorrentFlowTheme.accent),
                  ),
                if (onDownload != null)
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    onPressed: onDownload,
                    child: Icon(CupertinoIcons.arrow_down_to_line, size: 16, color: TorrentFlowTheme.success),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
            child: Text(label, style: TextStyle(
              fontSize: 10,
              color: color,
            )),
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
