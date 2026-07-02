import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/downloads/download_providers.dart';

class AddTorrentScreen extends ConsumerStatefulWidget {
  const AddTorrentScreen({super.key});

  @override
  ConsumerState<AddTorrentScreen> createState() => _AddTorrentScreenState();
}

class _AddTorrentScreenState extends ConsumerState<AddTorrentScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Add Torrent', style: TorrentFlowTheme.headline.copyWith(
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
        child: Padding(
          padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _AddButton(
                icon: CupertinoIcons.link,
                title: 'Magnet Link',
                subtitle: 'Paste a magnet link to start downloading',
                onTap: _showMagnetInput,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              _AddButton(
                icon: CupertinoIcons.doc,
                title: 'Torrent File',
                subtitle: 'Import a .torrent file from your device',
                onTap: _pickTorrentFile,
                isDark: isDark,
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  void _showMagnetInput() {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Add Magnet Link'),
        content: CupertinoTextField(
          controller: controller,
          placeholder: 'magnet:?xt=urn:btih:...',
          autofocus: true,
          maxLines: 3,
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
                _startMagnetDownload(controller.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _startMagnetDownload(String magnetUri) async {
    final notifier = ref.read(downloadTasksProvider.notifier);
    final docsDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${docsDir.path}/Downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    final savePath = '${downloadsDir.path}/magnet_download';

    try {
      await notifier.addDownload(
        title: 'Magnet Download',
        url: magnetUri,
        savePath: savePath,
        magnetUri: magnetUri,
      ).first;
      if (mounted) {
        _showToast('Download added');
      }
    } catch (e) {
      if (mounted) {
        _showToast('Error: $e');
      }
    }
  }

  Future<void> _pickTorrentFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) return;

      final notifier = ref.read(downloadTasksProvider.notifier);
      final docsDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${docsDir.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final title = file.name.replaceAll('.torrent', '');
      final savePath = '${downloadsDir.path}/$title';

      await notifier.addDownload(
        title: title,
        url: file.path!,
        savePath: savePath,
      ).first;

      if (mounted) {
        _showToast('Torrent added: $title');
      }
    } catch (e) {
      if (mounted) {
        _showToast('Error: $e');
      }
    }
  }

  void _showToast(String message) {
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
}

class _AddButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _AddButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
        decoration: BoxDecoration(
          color: isDark ? TorrentFlowTheme.darkSurface2 : TorrentFlowTheme.lightSurface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? TorrentFlowTheme.darkSeparator : TorrentFlowTheme.lightSeparator,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: TorrentFlowTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: TorrentFlowTheme.accent, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TorrentFlowTheme.headline.copyWith(
                    color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                  )),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TorrentFlowTheme.footnote.copyWith(
                    color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                  )),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_forward, color: TorrentFlowTheme.darkTextSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
