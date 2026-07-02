import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/torrent.dart';
import '../../../providers/downloads/download_providers.dart';
import 'add_download_sheet.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedTasks = {};
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
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showAddOptions(context),
          child: Icon(CupertinoIcons.plus, color: TorrentFlowTheme.accent),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildStatsBar(stats, isDark),
            _buildFilterTabs(isDark),
            if (_selectionMode) _buildSelectionBar(isDark),
            Expanded(
              child: filteredTasks.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildDownloadList(filteredTasks, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(DownloadStats stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Active', count: stats.active, color: TorrentFlowTheme.accent),
          _StatItem(label: 'Paused', count: stats.paused, color: TorrentFlowTheme.paused),
          _StatItem(label: 'Complete', count: stats.completed, color: TorrentFlowTheme.success),
          _StatItem(label: 'Errors', count: stats.error, color: TorrentFlowTheme.error),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    final filters = ['all', 'active', 'paused', 'completed'];
    final labels = ['All', 'Active', 'Paused', 'Done'];

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
                      color: isActive ? TorrentFlowTheme.accent : CupertinoColors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(labels[i], style: TorrentFlowTheme.footnote.copyWith(
                  color: isActive ? TorrentFlowTheme.accent : TorrentFlowTheme.darkTextSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                )),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectionBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: TorrentFlowTheme.accent.withValues(alpha: 0.1),
      child: Row(
        children: [
          Text('${_selectedTasks.length} selected', style: TorrentFlowTheme.footnote.copyWith(
            color: TorrentFlowTheme.accent,
          )),
          const Spacer(),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: _selectedTasks.isEmpty ? null : () => _batchPause(),
            child: const Text('Pause', style: TextStyle(fontSize: 13)),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: _selectedTasks.isEmpty ? null : () => _batchResume(),
            child: const Text('Resume', style: TextStyle(fontSize: 13)),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: () => _batchRemove(),
            child: Text('Delete', style: TextStyle(fontSize: 13, color: TorrentFlowTheme.error)),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: () => setState(() {
              _selectionMode = false;
              _selectedTasks.clear();
            }),
            child: const Text('Done', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _batchPause() {
    final notifier = ref.read(downloadTasksProvider.notifier);
    for (final id in _selectedTasks) {
      notifier.pauseTask(id);
    }
    _selectedTasks.clear();
  }

  void _batchResume() {
    final notifier = ref.read(downloadTasksProvider.notifier);
    for (final id in _selectedTasks) {
      notifier.resumeTask(id);
    }
    _selectedTasks.clear();
  }

  void _batchRemove() {
    final notifier = ref.read(downloadTasksProvider.notifier);
    for (final id in _selectedTasks) {
      notifier.removeTask(id);
    }
    _selectedTasks.clear();
  }

  List<DownloadTask> _filterTasks(List<DownloadTask> tasks) {
    switch (_activeFilter) {
      case 'active':
        return tasks.where((t) => t.status == DownloadStatus.downloading || t.status == DownloadStatus.queued).toList();
      case 'paused':
        return tasks.where((t) => t.status == DownloadStatus.paused || t.status == DownloadStatus.stopped).toList();
      case 'completed':
        return tasks.where((t) => t.status == DownloadStatus.completed).toList();
      default:
        return tasks;
    }
  }

  Widget _buildEmptyState(bool isDark) {
    final messages = {
      'all': 'No downloads yet',
      'active': 'No active downloads',
      'paused': 'No paused downloads',
      'completed': 'No completed downloads',
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.arrow_down_circle, size: 48,
            color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
          const SizedBox(height: 12),
          Text(messages[_activeFilter]!, style: TorrentFlowTheme.body.copyWith(
            color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
          )),
          const SizedBox(height: 8),
          CupertinoButton(
            onPressed: () => _showAddOptions(context),
            child: const Text('Add your first download'),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadList(List<DownloadTask> tasks, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: TorrentFlowTheme.spacing),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isSelected = _selectedTasks.contains(task.id);
        return _DownloadCard(
          task: task,
          isDark: isDark,
          selectionMode: _selectionMode,
          isSelected: isSelected,
          onTap: () {
            if (_selectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedTasks.remove(task.id);
                } else {
                  _selectedTasks.add(task.id);
                }
              });
            } else {
              _showTaskOptions(task, isDark);
            }
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _selectionMode = true;
              _selectedTasks.add(task.id);
            });
          },
          onPause: () => ref.read(downloadTasksProvider.notifier).pauseTask(task.id),
          onResume: () => ref.read(downloadTasksProvider.notifier).resumeTask(task.id),
          onRemove: () => ref.read(downloadTasksProvider.notifier).removeTask(task.id),
        );
      },
    );
  }

  void _showTaskOptions(DownloadTask task, bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + TorrentFlowTheme.standardPadding,
        ),
        decoration: BoxDecoration(
          color: isDark ? TorrentFlowTheme.darkSurface : TorrentFlowTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
              child: Text(task.title, style: TorrentFlowTheme.title3, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.queued)
              _MenuButton(icon: CupertinoIcons.pause, label: 'Pause', onTap: () { ref.read(downloadTasksProvider.notifier).pauseTask(task.id); Navigator.of(ctx).pop(); }),
            if (task.status == DownloadStatus.paused)
              _MenuButton(icon: CupertinoIcons.play, label: 'Resume', onTap: () { ref.read(downloadTasksProvider.notifier).resumeTask(task.id); Navigator.of(ctx).pop(); }),
            if (task.status == DownloadStatus.error)
              _MenuButton(icon: CupertinoIcons.refresh, label: 'Retry', onTap: () { ref.read(downloadTasksProvider.notifier).retryTask(task.id); Navigator.of(ctx).pop(); }),
            _MenuButton(icon: CupertinoIcons.trash, label: 'Remove', isDestructive: true, onTap: () { ref.read(downloadTasksProvider.notifier).removeTask(task.id); Navigator.of(ctx).pop(); }),
          ],
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + TorrentFlowTheme.standardPadding,
        ),
        decoration: BoxDecoration(
          color: CupertinoTheme.brightnessOf(context) == Brightness.dark
              ? TorrentFlowTheme.darkSurface
              : TorrentFlowTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
              child: Text('Add Download', style: TorrentFlowTheme.title3),
            ),
            _MenuButton(icon: CupertinoIcons.link, label: 'Paste Magnet Link', onTap: () { Navigator.of(context).pop(); _showMagnetInput(context); }),
            _MenuButton(icon: CupertinoIcons.doc, label: 'Import .torrent File', onTap: () { Navigator.of(context).pop(); _importTorrentFile(context); }),
          ],
        ),
      ),
    );
  }

  void _showMagnetInput(BuildContext context) {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Add Magnet Link'),
        content: CupertinoTextField(
          controller: controller,
          placeholder: 'magnet:?xt=urn:btih:...',
          autofocus: true,
        ),
        actions: [
          CupertinoButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoButton(
            child: const Text('Add'),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.of(context).pop();
                showCupertinoModalPopup(
                  context: context,
                  builder: (context) => AddDownloadSheet(magnetUri: controller.text),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _importTorrentFile(BuildContext context) {
    // File picker integration
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Import .torrent'),
        content: const Text('Select a .torrent file from your device.'),
        actions: [
          CupertinoButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoButton(
            child: const Text('Browse'),
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Integrate file_picker
            },
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuButton({required this.icon, required this.label, this.isDestructive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, color: isDestructive ? TorrentFlowTheme.error : TorrentFlowTheme.accent),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: isDestructive ? TorrentFlowTheme.error : null)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatItem({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count', style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: color,
        )),
        Text(label, style: TorrentFlowTheme.caption1.copyWith(
          color: TorrentFlowTheme.darkTextSecondary,
        )),
      ],
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final DownloadTask task;
  final bool isDark;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onRemove;

  const _DownloadCard({
    required this.task,
    required this.isDark,
    this.selectionMode = false,
    this.isSelected = false,
    required this.onTap,
    this.onLongPress,
    this.onPause,
    this.onResume,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              ProgressRing(progress: task.progress),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: TorrentFlowTheme.callout.copyWith(
                      color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                      fontWeight: FontWeight.w500,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(task.formattedProgress, style: TorrentFlowTheme.footnote.copyWith(
                      color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                    )),
                  ],
                ),
              ),
              _StatusBadge(status: task.status, isDark: isDark),
              if (!selectionMode) ...[
                if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.queued)
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    onPressed: onPause,
                    child: Icon(CupertinoIcons.pause_circle, size: 22, color: TorrentFlowTheme.warning),
                  ),
                if (task.status == DownloadStatus.paused)
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    onPressed: onResume,
                    child: Icon(CupertinoIcons.play_circle, size: 22, color: TorrentFlowTheme.success),
                  ),
                if (task.status == DownloadStatus.error)
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    onPressed: onRemove,
                    child: Icon(CupertinoIcons.xmark_circle, size: 22, color: TorrentFlowTheme.error),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isDark ? TorrentFlowTheme.darkSurface3 : TorrentFlowTheme.lightSurface2,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: task.progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: _statusColor(task.status),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TaskStat(icon: CupertinoIcons.arrow_down, value: task.formattedSpeed, isDark: isDark),
              if (task.uploadSpeed > 0) ...[
                const SizedBox(width: 12),
                _TaskStat(icon: CupertinoIcons.arrow_up, value: task.formattedUploadSpeed, isDark: isDark),
              ],
              if (task.peers > 0) ...[
                const SizedBox(width: 12),
                _TaskStat(icon: CupertinoIcons.person_2, value: '${task.peers}', isDark: isDark),
              ],
              const Spacer(),
              Text(task.remainingFormatted, style: TorrentFlowTheme.caption1.copyWith(
                color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
              )),
              if (task.priority != DownloadPriority.normal) ...[
                const SizedBox(width: 8),
                Icon(
                  task.priority == DownloadPriority.high ? CupertinoIcons.exclamationmark_circle : CupertinoIcons.chevron_down_circle,
                  size: 14,
                  color: task.priority == DownloadPriority.high ? TorrentFlowTheme.warning : TorrentFlowTheme.darkTextSecondary,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(DownloadStatus status) {
    return switch (status) {
      DownloadStatus.downloading => TorrentFlowTheme.accent,
      DownloadStatus.seeding => TorrentFlowTheme.success,
      DownloadStatus.paused => TorrentFlowTheme.paused,
      DownloadStatus.stopped => TorrentFlowTheme.stopped,
      DownloadStatus.completed => TorrentFlowTheme.success,
      DownloadStatus.error => TorrentFlowTheme.error,
      DownloadStatus.verifying => TorrentFlowTheme.warning,
      DownloadStatus.queued => TorrentFlowTheme.darkTextSecondary,
    };
  }
}

class _StatusBadge extends StatelessWidget {
  final DownloadStatus status;
  final bool isDark;

  const _StatusBadge({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      DownloadStatus.downloading => 'Downloading',
      DownloadStatus.seeding => 'Seeding',
      DownloadStatus.paused => 'Paused',
      DownloadStatus.stopped => 'Stopped',
      DownloadStatus.completed => 'Complete',
      DownloadStatus.error => 'Error',
      DownloadStatus.verifying => 'Verifying',
      DownloadStatus.queued => 'Queued',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _statusColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TorrentFlowTheme.caption2.copyWith(
        color: _statusColor(),
        fontWeight: FontWeight.w600,
      )),
    );
  }

  Color _statusColor() {
    return switch (status) {
      DownloadStatus.downloading => TorrentFlowTheme.accent,
      DownloadStatus.seeding => TorrentFlowTheme.success,
      DownloadStatus.paused => TorrentFlowTheme.paused,
      DownloadStatus.stopped => TorrentFlowTheme.stopped,
      DownloadStatus.completed => TorrentFlowTheme.success,
      DownloadStatus.error => TorrentFlowTheme.error,
      DownloadStatus.verifying => TorrentFlowTheme.warning,
      DownloadStatus.queued => TorrentFlowTheme.darkTextSecondary,
    };
  }
}

class _TaskStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;

  const _TaskStat({required this.icon, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: TorrentFlowTheme.darkTextSecondary),
        const SizedBox(width: 3),
        Text(value, style: TorrentFlowTheme.caption1.copyWith(
          color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
        )),
      ],
    );
  }
}
