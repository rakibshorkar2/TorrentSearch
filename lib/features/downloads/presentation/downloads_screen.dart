import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/torrent.dart';
import '../../../providers/app_providers.dart';
import 'add_download_sheet.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final tasks = ref.watch(downloadTasksProvider);

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
        child: tasks.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.arrow_down_circle, size: 48,
                      color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
                    const SizedBox(height: 12),
                    Text('No downloads yet', style: TorrentFlowTheme.body.copyWith(
                      color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                    )),
                    const SizedBox(height: 8),
                    CupertinoButton(
                      onPressed: () => _showAddOptions(context),
                      child: const Text('Add your first download'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
                itemCount: tasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: TorrentFlowTheme.spacing),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return _DownloadCard(task: task, isDark: isDark);
                },
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
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onPressed: () {
                Navigator.of(context).pop();
                _showMagnetInput(context);
              },
              child: Row(
                children: [
                  const Icon(CupertinoIcons.link),
                  const SizedBox(width: 12),
                  const Text('Paste Magnet Link'),
                ],
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onPressed: () {
                Navigator.of(context).pop();
                _importTorrentFile(context);
              },
              child: Row(
                children: [
                  const Icon(CupertinoIcons.doc),
                  const SizedBox(width: 12),
                  const Text('Import .torrent File'),
                ],
              ),
            ),
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
    // File picker integration would go here
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
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final DownloadTask task;
  final bool isDark;

  const _DownloadCard({required this.task, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
              _StatItem(icon: CupertinoIcons.arrow_down, value: task.formattedSpeed, isDark: isDark),
              if (task.uploadSpeed > 0) ...[
                const SizedBox(width: 12),
                _StatItem(icon: CupertinoIcons.arrow_up, value: task.formattedUploadSpeed, isDark: isDark),
              ],
              if (task.peers > 0) ...[
                const SizedBox(width: 12),
                _StatItem(icon: CupertinoIcons.person_2, value: '${task.peers}', isDark: isDark),
              ],
              const Spacer(),
              Text(task.remainingFormatted, style: TorrentFlowTheme.caption1.copyWith(
                color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
              )),
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;

  const _StatItem({required this.icon, required this.value, required this.isDark});

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
