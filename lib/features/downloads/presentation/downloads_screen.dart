import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/torrent.dart';
import '../../../providers/downloads/download_providers.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  String _activeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final tasks = ref.watch(downloadTasksProvider);
    final stats = ref.watch(downloadStatsProvider);

    final filteredTasks = _filterTasks(tasks);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Downloads', style: TorrentFlowTheme.headline.copyWith(
          color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
        )),
        backgroundColor: isDark
            ? TorrentFlowTheme.darkSurface.withValues(alpha: 0.85)
            : TorrentFlowTheme.lightSurface.withValues(alpha: 0.85),
        border: Border(bottom: BorderSide(
          color: isDark ? TorrentFlowTheme.darkSeparator : TorrentFlowTheme.lightSeparator,
          width: 0.5,
        )),
        trailing: filteredTasks.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showSortOptions(),
                child: const Icon(CupertinoIcons.arrow_up_arrow_down, size: 20),
              )
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildFilterBar(isDark, stats),
            Expanded(
              child: filteredTasks.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildTaskList(filteredTasks, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isDark, DownloadStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(label: 'All (${stats.total})', filter: 'all', isDark: isDark),
            const SizedBox(width: 6),
            _buildFilterChip(label: 'Active (${stats.active})', filter: 'active', isDark: isDark),
            const SizedBox(width: 6),
            _buildFilterChip(label: 'Completed (${stats.completed})', filter: 'completed', isDark: isDark),
            const SizedBox(width: 6),
            _buildFilterChip(label: 'Paused (${stats.paused})', filter: 'paused', isDark: isDark),
            const SizedBox(width: 6),
            _buildFilterChip(label: 'Errors (${stats.error})', filter: 'error', isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required String filter, required bool isDark}) {
    final isSelected = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? TorrentFlowTheme.accent.withValues(alpha: 0.15)
              : (isDark ? TorrentFlowTheme.darkSurface3 : TorrentFlowTheme.lightSurface2),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: TorrentFlowTheme.accent.withValues(alpha: 0.5))
              : null,
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? TorrentFlowTheme.accent : TorrentFlowTheme.darkTextSecondary,
        )),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.arrow_down_circle, size: 56,
            color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
          const SizedBox(height: 16),
          Text('No downloads yet', style: TorrentFlowTheme.body.copyWith(
            color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
          )),
          const SizedBox(height: 8),
          Text('Add a magnet link or torrent file to start',
            style: TorrentFlowTheme.footnote.copyWith(
              color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
            )),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<DownloadTask> tasks, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding, vertical: 4),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: TorrentFlowTheme.spacing),
      itemBuilder: (context, index) => _TorrentTaskCard(
        task: tasks[index],
        isDark: isDark,
        onTap: () => _showTaskDetails(tasks[index]),
        onPause: () => ref.read(downloadTasksProvider.notifier).pauseTask(tasks[index].id),
        onResume: () => ref.read(downloadTasksProvider.notifier).resumeTask(tasks[index].id),
        onDelete: () => _confirmDelete(tasks[index]),
      ),
    );
  }

  void _showTaskDetails(DownloadTask task) {
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _TorrentDetailSheet(task: task),
    );
  }

  void _confirmDelete(DownloadTask task) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Remove Download'),
        content: Text('Remove "${task.title}" from the list?'),
        actions: [
          CupertinoButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoButton(
            child: const Text('Remove', style: TextStyle(color: CupertinoColors.systemRed)),
            onPressed: () {
              ref.read(downloadTasksProvider.notifier).removeTask(task.id);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 8),
        decoration: BoxDecoration(
          color: CupertinoTheme.brightnessOf(ctx) == Brightness.dark
              ? TorrentFlowTheme.darkSurface : TorrentFlowTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: TorrentFlowTheme.darkTextSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
              child: Text('Sort By', style: TorrentFlowTheme.title3),
            ),
            _SortOption(label: 'Date Added', value: 'date'),
            _SortOption(label: 'Name', value: 'name'),
            _SortOption(label: 'Progress', value: 'progress'),
            _SortOption(label: 'Size', value: 'size'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<DownloadTask> _filterTasks(List<DownloadTask> tasks) {
    var result = tasks;
    switch (_activeFilter) {
      case 'active':
        result = result.where((t) => t.status == DownloadStatus.downloading || t.status == DownloadStatus.queued).toList();
        break;
      case 'completed':
        result = result.where((t) => t.status == DownloadStatus.completed).toList();
        break;
      case 'paused':
        result = result.where((t) => t.status == DownloadStatus.paused || t.status == DownloadStatus.stopped).toList();
        break;
      case 'error':
        result = result.where((t) => t.status == DownloadStatus.error).toList();
        break;
    }
    return result;
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final String value;
  const _SortOption({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Text(label, style: TorrentFlowTheme.body),
          const Spacer(),
          Icon(CupertinoIcons.chevron_forward, size: 14, color: TorrentFlowTheme.darkTextSecondary),
        ],
      ),
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

class _TorrentTaskCard extends StatelessWidget {
  final DownloadTask task;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  const _TorrentTaskCard({
    required this.task,
    required this.isDark,
    required this.onTap,
    required this.onPause,
    required this.onResume,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = task.status == DownloadStatus.downloading;
    final progressColor = task.status == DownloadStatus.error
        ? TorrentFlowTheme.error
        : task.status == DownloadStatus.paused
            ? TorrentFlowTheme.warning
            : TorrentFlowTheme.accent;

    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(task.title, style: TorrentFlowTheme.callout.copyWith(
                  color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                  fontWeight: FontWeight.w500,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              _StatusBadge(status: task.status, isDark: isDark),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? TorrentFlowTheme.darkSurface3 : TorrentFlowTheme.lightSurface2,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: task.progress > 0 ? task.progress : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(task.formattedProgress, style: TorrentFlowTheme.caption1.copyWith(
                color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                fontWeight: FontWeight.w600,
              )),
              const SizedBox(width: 8),
              Text('${task.formattedDownloaded} / ${task.formattedTotal}', style: TorrentFlowTheme.caption1.copyWith(
                color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
              )),
              if (isActive && task.downloadSpeed > 0) ...[
                const Spacer(),
                Icon(CupertinoIcons.arrow_down_circle, size: 12,
                  color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
                const SizedBox(width: 3),
                Text(task.formattedSpeed, style: TorrentFlowTheme.caption1.copyWith(
                  color: TorrentFlowTheme.success,
                )),
              ],
            ],
          ),
          if (task.totalSize > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (isActive && task.downloadSpeed > 0) ...[
                  Icon(CupertinoIcons.antenna_radiowaves_left_right, size: 12,
                    color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
                  const SizedBox(width: 3),
                  Text('${task.peers} peers', style: TorrentFlowTheme.caption1.copyWith(
                    color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                  )),
                  const SizedBox(width: 8),
                  Text('${task.seeders} seeds', style: TorrentFlowTheme.caption1.copyWith(
                    color: TorrentFlowTheme.success,
                  )),
                  if (task.eta != null) ...[
                    const SizedBox(width: 8),
                    Icon(CupertinoIcons.clock, size: 12,
                      color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
                    const SizedBox(width: 3),
                    Text(_formatEta(task.eta!), style: TorrentFlowTheme.caption1.copyWith(
                      color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                    )),
                  ],
                ],
                const Spacer(),
                if (task.status == DownloadStatus.downloading)
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    onPressed: onPause,
                    child: Icon(CupertinoIcons.pause_circle, size: 22, color: TorrentFlowTheme.warning),
                  )
                else if (task.status == DownloadStatus.paused)
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    onPressed: onResume,
                    child: Icon(CupertinoIcons.play_circle, size: 22, color: TorrentFlowTheme.success),
                  ),
                CupertinoButton(
                  padding: const EdgeInsets.all(4),
                  onPressed: onDelete,
                  child: Icon(CupertinoIcons.trash_circle, size: 22, color: TorrentFlowTheme.error),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatEta(Duration eta) {
    if (eta.inDays > 0) return '${eta.inDays}d ${eta.inHours % 24}h';
    if (eta.inHours > 0) return '${eta.inHours}h ${eta.inMinutes % 60}m';
    if (eta.inMinutes > 0) return '${eta.inMinutes}m ${eta.inSeconds % 60}s';
    return '${eta.inSeconds}s';
  }
}

class _StatusBadge extends StatelessWidget {
  final DownloadStatus status;
  final bool isDark;
  const _StatusBadge({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case DownloadStatus.downloading:
        color = TorrentFlowTheme.accent;
        label = 'Downloading';
        break;
      case DownloadStatus.completed:
        color = TorrentFlowTheme.success;
        label = 'Completed';
        break;
      case DownloadStatus.paused:
        color = TorrentFlowTheme.warning;
        label = 'Paused';
        break;
      case DownloadStatus.error:
        color = TorrentFlowTheme.error;
        label = 'Error';
        break;
      case DownloadStatus.queued:
        color = TorrentFlowTheme.darkTextSecondary;
        label = 'Queued';
        break;
      default:
        color = TorrentFlowTheme.darkTextSecondary;
        label = status.name;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _TorrentDetailSheet extends StatelessWidget {
  final DownloadTask task;
  const _TorrentDetailSheet({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + TorrentFlowTheme.standardPadding),
      decoration: BoxDecoration(
        color: isDark ? TorrentFlowTheme.darkSurface : TorrentFlowTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: TorrentFlowTheme.darkTextSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
            child: Text(task.title, style: TorrentFlowTheme.title3.copyWith(
              color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
            )),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
            child: _detailRow('Status', task.status.name, isDark),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
            child: _detailRow('Progress', task.formattedProgress, isDark),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
            child: _detailRow('Downloaded', task.formattedDownloaded, isDark),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
            child: _detailRow('Total Size', task.formattedTotal, isDark),
          ),
          if (task.downloadSpeed > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
              child: _detailRow('Speed', task.formattedSpeed, isDark),
            ),
          if (task.peers > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
              child: _detailRow('Peers', '${task.peers}', isDark),
            ),
          if (task.seeders > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
              child: _detailRow('Seeds', '${task.seeders}', isDark),
            ),
          if (task.infoHash != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
              child: _detailRow('Info Hash', task.infoHash!, isDark),
            ),
          const SizedBox(height: 16),
          Center(
            child: CupertinoButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TorrentFlowTheme.footnote.copyWith(
              color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
            )),
          ),
          Expanded(
            child: Text(value, style: TorrentFlowTheme.body.copyWith(
              color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
            )),
          ),
        ],
      ),
    );
  }
}
