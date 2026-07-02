import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/history_item.dart';
import '../../../providers/history/history_providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _activeFilter = 'all';
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final history = ref.watch(historyProvider);

    final filtered = _filterItems(history);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: _showSearch
            ? CupertinoTextField(
                controller: _searchController,
                placeholder: 'Search history...',
                placeholderStyle: TextStyle(color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
                style: TextStyle(color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText),
                autofocus: true,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: BoxDecoration(
                  color: isDark ? TorrentFlowTheme.darkSurface2 : TorrentFlowTheme.lightSurface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              )
            : Text('History',
                style: TorrentFlowTheme.headline.copyWith(
                  color: isDark
                      ? TorrentFlowTheme.darkText
                      : TorrentFlowTheme.lightText,
                )),
        backgroundColor: isDark
            ? TorrentFlowTheme.darkSurface.withValues(alpha: 0.85)
            : TorrentFlowTheme.lightSurface.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? TorrentFlowTheme.darkSeparator
                : TorrentFlowTheme.lightSeparator,
            width: 0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => setState(() => _showSearch = !_showSearch),
          child: Icon(
            _showSearch ? CupertinoIcons.xmark_circle : CupertinoIcons.search,
            color: TorrentFlowTheme.accent,
          ),
        ),
        trailing: history.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showClearOptions(context),
                child: Icon(CupertinoIcons.trash,
                    color: TorrentFlowTheme.error, size: 20),
              )
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildFilterTabs(isDark),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildHistoryList(filtered, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    final filters = ['all', 'magnet', 'download'];
    final labels = ['All', 'Magnets', 'Downloads'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: List.generate(filters.length, (i) {
          final isActive = _activeFilter == filters[i];
          return Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 6),
              onPressed: () => setState(() => _activeFilter = filters[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? TorrentFlowTheme.accent
                          : CupertinoColors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(labels[i],
                    style: TorrentFlowTheme.footnote.copyWith(
                      color: isActive
                          ? TorrentFlowTheme.accent
                          : TorrentFlowTheme.darkTextSecondary,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                    )),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<HistoryItem> _filterItems(List<HistoryItem> items) {
    var result = items;
    switch (_activeFilter) {
      case 'magnet':
        result = result.where((i) => i.type == HistoryItemType.magnetLink).toList();
      case 'download':
        result = result.where((i) => i.type == HistoryItemType.download).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result.where((i) => i.title.toLowerCase().contains(_searchQuery)).toList();
    }
    return result;
  }

  Widget _buildEmptyState(bool isDark) {
    final messages = {
      'all': 'No history yet',
      'magnet': 'No magnet links saved',
      'download': 'No downloads recorded',
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.clock,
              size: 48,
              color: isDark
                  ? TorrentFlowTheme.darkTextSecondary
                  : TorrentFlowTheme.lightTextSecondary),
          const SizedBox(height: 12),
          Text(messages[_activeFilter]!,
              style: TorrentFlowTheme.body.copyWith(
                color: isDark
                    ? TorrentFlowTheme.darkTextSecondary
                    : TorrentFlowTheme.lightTextSecondary,
              )),
          const SizedBox(height: 8),
          Text('Items you save will appear here',
              style: TorrentFlowTheme.footnote.copyWith(
                color: isDark
                    ? TorrentFlowTheme.darkTextSecondary
                    : TorrentFlowTheme.lightTextSecondary,
              )),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<HistoryItem> items, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: TorrentFlowTheme.spacing),
      itemBuilder: (context, index) {
        final item = items[index];
        return _HistoryCard(
          item: item,
          isDark: isDark,
          onTap: () => _copyMagnet(item, isDark),
          onDelete: () => _deleteItem(item),
        );
      },
    );
  }

  void _copyMagnet(HistoryItem item, bool isDark) {
    if (item.magnetUri != null) {
      Clipboard.setData(ClipboardData(text: item.magnetUri!));
      HapticFeedback.lightImpact();
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Icon(CupertinoIcons.checkmark_circle,
              color: TorrentFlowTheme.success, size: 40),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Magnet link copied to clipboard',
                textAlign: TextAlign.center),
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
  }

  void _deleteItem(HistoryItem item) {
    ref.read(historyProvider.notifier).removeItem(item.id);
  }

  void _showClearOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Clear History'),
        message: const Text('Choose what to clear'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(historyProvider.notifier).clearMagnetLinks();
            },
            child: const Text('Clear Magnet Links'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(historyProvider.notifier).clearDownloads();
            },
            child: const Text('Clear Downloads'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(historyProvider.notifier).clearAll();
            },
            child: const Text('Clear All'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryItem item;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.item,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _typeColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon(), size: 20, color: _typeColor()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: TorrentFlowTheme.callout.copyWith(
                      color: isDark
                          ? TorrentFlowTheme.darkText
                          : TorrentFlowTheme.lightText,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _TypeBadge(
                      type: item.type,
                      isDark: isDark,
                    ),
                    if (item.formattedSize.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(item.formattedSize,
                          style: TorrentFlowTheme.caption1.copyWith(
                            color: TorrentFlowTheme.darkTextSecondary,
                          )),
                    ],
                    const SizedBox(width: 8),
                    Text(_timeAgo(item.addedAt),
                        style: TorrentFlowTheme.caption1.copyWith(
                          color: TorrentFlowTheme.darkTextSecondary,
                        )),
                  ],
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(4),
            onPressed: onDelete,
            child: Icon(CupertinoIcons.trash,
                size: 16, color: TorrentFlowTheme.error),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon() {
    return switch (item.type) {
      HistoryItemType.magnetLink => CupertinoIcons.link,
      HistoryItemType.download => CupertinoIcons.arrow_down_circle,
    };
  }

  Color _typeColor() {
    return switch (item.type) {
      HistoryItemType.magnetLink => TorrentFlowTheme.accent,
      HistoryItemType.download => TorrentFlowTheme.success,
    };
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class _TypeBadge extends StatelessWidget {
  final HistoryItemType type;
  final bool isDark;

  const _TypeBadge({required this.type, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final label = type == HistoryItemType.magnetLink ? 'Magnet' : 'Download';
    final color = type == HistoryItemType.magnetLink
        ? TorrentFlowTheme.accent
        : TorrentFlowTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
