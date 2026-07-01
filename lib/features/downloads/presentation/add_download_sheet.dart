import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/torrent.dart';
import '../../../providers/app_providers.dart';

class AddDownloadSheet extends ConsumerWidget {
  final TorrentInfo? torrent;
  final String? magnetUri;

  const AddDownloadSheet({
    super.key,
    this.torrent,
    this.magnetUri,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final title = torrent?.title ?? magnetUri ?? 'Unknown Torrent';

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
              width: 36,
              height: 4,
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
          if (torrent != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
              child: Text('Size: ${torrent!.formattedSize} | ${torrent!.seeders} seeders',
                style: TorrentFlowTheme.footnote.copyWith(
                  color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                )),
            ),
          ],
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: () {
                  final downloadService = ref.read(downloadServiceProvider);
                  downloadService.addDownload(
                    title: title,
                    url: magnetUri ?? torrent?.magnetUri ?? '',
                    savePath: '/downloads/${title.replaceAll(RegExp(r'[^\w\s]'), '')}',
                    magnetUri: magnetUri ?? torrent?.magnetUri,
                    infoHash: torrent?.infoHash,
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Start Download'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
