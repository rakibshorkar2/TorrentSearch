import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/torrent.dart';
import '../../../providers/app_providers.dart';

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
              child: Text('Size: ${widget.torrent!.formattedSize} | ${widget.torrent!.seeders} seeders',
                style: TorrentFlowTheme.footnote.copyWith(
                  color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                )),
            ),
          ],
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

      await notifier.addDownload(
        title: title,
        url: url,
        savePath: '/downloads/${title.replaceAll(RegExp(r'[^\w\s]'), '')}',
        magnetUri: widget.magnetUri ?? widget.torrent?.magnetUri,
        infoHash: infoHash,
      ).first;

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }
}
