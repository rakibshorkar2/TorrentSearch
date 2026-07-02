import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/torrent.dart';
import '../../../providers/downloads/download_providers.dart';
import '../../../providers/history/history_providers.dart';

class AddDownloadSheet extends ConsumerStatefulWidget {
  final TorrentInfo? torrent;
  final String? magnetUri;

  const AddDownloadSheet({
    super.key,
    this.torrent,
    this.magnetUri,
  });

  @override
  ConsumerState<AddDownloadSheet> createState() => _AddDownloadSheetState();
}

class _AddDownloadSheetState extends ConsumerState<AddDownloadSheet> {
  bool _isAdding = false;
  String? _error;
  DownloadPriority _priority = DownloadPriority.normal;
  final _limitController = TextEditingController();

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final title = widget.torrent?.title ?? widget.magnetUri ?? 'Unknown Torrent';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + TorrentFlowTheme.standardPadding,
      ),
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
                color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
            child: Text('Add Download', style: TorrentFlowTheme.title3.copyWith(
              color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
            )),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
            child: Text(title, style: TorrentFlowTheme.callout.copyWith(
              color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
            ), maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
          if (widget.torrent != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
              child: Row(
                children: [
                  if (widget.torrent!.source != null)
                    _Badge(label: widget.torrent!.source!, color: TorrentFlowTheme.accent),
                  const SizedBox(width: 8),
                  if (widget.torrent!.quality != null)
                    _Badge(label: widget.torrent!.quality!, color: TorrentFlowTheme.success),
                  const SizedBox(width: 8),
                  Text('Size: ${widget.torrent!.formattedSize} | ${widget.torrent!.seeders} seeders',
                    style: TorrentFlowTheme.footnote.copyWith(
                      color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                    )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
            child: Row(
              children: [
                Text('Priority:', style: TorrentFlowTheme.footnote.copyWith(
                  color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                )),
                const SizedBox(width: 12),
                _PriorityChip(
                  label: 'Low',
                  isSelected: _priority == DownloadPriority.low,
                  onTap: () => setState(() => _priority = DownloadPriority.low),
                ),
                const SizedBox(width: 8),
                _PriorityChip(
                  label: 'Normal',
                  isSelected: _priority == DownloadPriority.normal,
                  onTap: () => setState(() => _priority = DownloadPriority.normal),
                ),
                const SizedBox(width: 8),
                _PriorityChip(
                  label: 'High',
                  isSelected: _priority == DownloadPriority.high,
                  onTap: () => setState(() => _priority = DownloadPriority.high),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
              child: Text(_error!, style: TorrentFlowTheme.footnote.copyWith(color: TorrentFlowTheme.error)),
            ),
          ],
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: _isAdding ? null : _addDownload,
                child: _isAdding
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text('Start Download'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                onPressed: _isAdding ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addDownload() async {
    setState(() {
      _isAdding = true;
      _error = null;
    });
    try {
      final notifier = ref.read(downloadTasksProvider.notifier);
      final title = widget.torrent?.title ?? widget.magnetUri ?? 'Unknown Torrent';
      final url = widget.magnetUri ?? widget.torrent?.magnetUri ?? '';
      final infoHash = widget.torrent?.infoHash;

      if (url.isEmpty) {
        throw Exception('No download URL or magnet link available');
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${docsDir.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final safeName = title.replaceAll(RegExp(r'[^\w\s\-.]'), '').trim();
      final savePath = '${downloadsDir.path}/${safeName.isNotEmpty ? safeName : 'download'}';

      await notifier.addDownload(
        title: title,
        url: url,
        savePath: savePath,
        magnetUri: widget.magnetUri ?? widget.torrent?.magnetUri,
        infoHash: infoHash,
        downloadLimit: null,
        uploadLimit: null,
      ).first;

      ref.read(historyProvider.notifier).addDownload(
        title: title,
        magnetUri: url,
        infoHash: infoHash,
        totalSize: widget.torrent?.size,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? TorrentFlowTheme.accent.withValues(alpha: 0.15) : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? TorrentFlowTheme.accent : TorrentFlowTheme.darkTextSecondary,
            width: 0.5,
          ),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12,
          color: isSelected ? TorrentFlowTheme.accent : TorrentFlowTheme.darkTextSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        )),
      ),
    );
  }
}
