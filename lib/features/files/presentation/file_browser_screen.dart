import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class FileBrowserScreen extends ConsumerStatefulWidget {
  final String? initialPath;

  const FileBrowserScreen({super.key, this.initialPath});

  @override
  ConsumerState<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends ConsumerState<FileBrowserScreen> {
  String _currentPath = '';
  List<FileSystemEntity> _entities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPath();
  }

  Future<void> _initPath() async {
    final dir = widget.initialPath ?? (await getApplicationDocumentsDirectory()).path;
    await _navigateTo(dir);
  }

  Future<void> _navigateTo(String path) async {
    setState(() => _isLoading = true);
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        final entities = await dir.list().toList();
        entities.sort((a, b) {
          if (a is Directory && b is! Directory) return -1;
          if (a is! Directory && b is Directory) return 1;
          return a.path.compareTo(b.path);
        });
        if (mounted) {
          setState(() {
            _currentPath = path;
            _entities = entities;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_getFolderName(), style: TorrentFlowTheme.headline.copyWith(
          color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
        )),
        backgroundColor: isDark
            ? TorrentFlowTheme.darkSurface.withValues(alpha: 0.85)
            : TorrentFlowTheme.lightSurface.withValues(alpha: 0.85),
        border: Border(bottom: BorderSide(
          color: isDark ? TorrentFlowTheme.darkSeparator : TorrentFlowTheme.lightSeparator,
          width: 0.5,
        )),
        leading: _currentPath.isNotEmpty && _currentPath != '/'
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _navigateTo(Directory(_currentPath).parent.path),
                child: Icon(CupertinoIcons.chevron_left, color: TorrentFlowTheme.accent),
              )
            : null,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _entities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.folder_open, size: 48,
                          color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
                        const SizedBox(height: 12),
                        Text('Empty folder', style: TorrentFlowTheme.body.copyWith(
                          color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                        )),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
                    itemCount: _entities.length,
                    separatorBuilder: (context, index) => const SizedBox(height: TorrentFlowTheme.tightPadding),
                    itemBuilder: (context, index) {
                      final entity = _entities[index];
                      return _FileEntityTile(
                        entity: entity,
                        isDark: isDark,
                        onTap: () {
                          if (entity is Directory) {
                            _navigateTo(entity.path);
                          } else {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (ctx) => _FileOptionsSheet(entity: entity, isDark: isDark, refresh: _refreshCurrent),
                            );
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }

  void _refreshCurrent() => _navigateTo(_currentPath);

  String _getFolderName() {
    final parts = _currentPath.split(Platform.pathSeparator);
    return parts.isNotEmpty ? parts.last : 'Files';
  }
}

class _FileEntityTile extends StatelessWidget {
  final FileSystemEntity entity;
  final bool isDark;
  final VoidCallback onTap;

  const _FileEntityTile({
    required this.entity,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDir = entity is Directory;
    final name = entity.path.split(Platform.pathSeparator).last;
    final icon = isDir
        ? CupertinoIcons.folder
        : _iconForExtension(name.contains('.') ? name.split('.').last.toLowerCase() : '');

    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isDir
                  ? TorrentFlowTheme.warning.withValues(alpha: 0.15)
                  : TorrentFlowTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20,
              color: isDir ? TorrentFlowTheme.warning : TorrentFlowTheme.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: TorrentFlowTheme.callout.copyWith(
              color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Icon(CupertinoIcons.chevron_forward, size: 14,
            color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
        ],
      ),
    );
  }

  IconData _iconForExtension(String ext) {
    switch (ext) {
      case 'mp4': case 'mov': case 'avi': case 'mkv':
        return CupertinoIcons.play_circle;
      case 'mp3': case 'wav': case 'flac':
        return CupertinoIcons.music_note;
      case 'jpg': case 'jpeg': case 'png': case 'gif':
        return CupertinoIcons.photo;
      case 'pdf':
        return CupertinoIcons.doc_text;
      case 'zip': case 'rar': case 'tar': case 'gz':
        return CupertinoIcons.archivebox;
      case 'torrent':
        return CupertinoIcons.link;
      default:
        return CupertinoIcons.doc;
    }
  }
}

class _FileOptionsSheet extends StatelessWidget {
  final FileSystemEntity entity;
  final bool isDark;
  final VoidCallback refresh;

  const _FileOptionsSheet({
    required this.entity,
    required this.isDark,
    required this.refresh,
  });

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
            child: Text(entity.path.split(Platform.pathSeparator).last,
              style: TorrentFlowTheme.title3, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          if (entity is File) ...[
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onPressed: () => Navigator.of(context).pop(),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.share),
                  const SizedBox(width: 12),
                  const Text('Share'),
                ],
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onPressed: () {
                Navigator.of(context).pop();
                if (entity is File) _previewFile(context, entity as File);
              },
              child: Row(
                children: [
                  const Icon(CupertinoIcons.eye),
                  const SizedBox(width: 12),
                  const Text('Preview'),
                ],
              ),
            ),
          ],
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            onPressed: () {
              Navigator.of(context).pop();
              _renameEntity(context, entity);
            },
            child: Row(
              children: [
                const Icon(CupertinoIcons.pencil),
                const SizedBox(width: 12),
                const Text('Rename'),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteEntity(context, entity);
            },
            child: Row(
              children: [
                const Icon(CupertinoIcons.trash, color: TorrentFlowTheme.error),
                const SizedBox(width: 12),
                Text('Delete', style: TextStyle(color: TorrentFlowTheme.error)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _previewFile(BuildContext context, File file) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Preview'),
        content: Text('Preview not yet implemented for: ${file.path.split(Platform.pathSeparator).last}'),
        actions: [
          CupertinoButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _renameEntity(BuildContext context, FileSystemEntity entity) {
    final name = entity.path.split(Platform.pathSeparator).last;
    final controller = TextEditingController(text: name);

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Rename'),
        content: CupertinoTextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          CupertinoButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoButton(
            child: const Text('Rename'),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != name) {
                final parent = entity.parent;
                final newPath = '${parent.path}${Platform.pathSeparator}$newName';
                entity.rename(newPath);
                refresh();
              }
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _deleteEntity(BuildContext context, FileSystemEntity entity) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete'),
        content: Text('Delete ${entity.path.split(Platform.pathSeparator).last}?'),
        actions: [
          CupertinoButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoButton(
            child: Text('Delete', style: const TextStyle(color: TorrentFlowTheme.error)),
            onPressed: () {
              entity.delete(recursive: entity is Directory);
              refresh();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}
