import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/theme/app_theme.dart';

class FileBrowserScreen extends ConsumerStatefulWidget {
  final Directory? initialDirectory;

  const FileBrowserScreen({super.key, this.initialDirectory});

  @override
  ConsumerState<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends ConsumerState<FileBrowserScreen> {
  Directory? _currentDir;
  List<FileSystemEntity> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initDir();
  }

  Future<void> _initDir() async {
    final dir = widget.initialDirectory;
    if (dir != null) {
      await _navigateTo(dir);
      return;
    }
    final docsDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${docsDir.path}${Platform.pathSeparator}Downloads');
    if (await downloadsDir.exists()) {
      await _navigateTo(downloadsDir);
    } else {
      await _navigateTo(docsDir);
    }
  }

  Future<void> _navigateTo(Directory dir) async {
    setState(() => _loading = true);
    try {
      final entries = dir.listSync()..sort(_compareEntities);
      if (mounted) {
        setState(() {
          _currentDir = dir;
          _entries = entries;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _compareEntities(FileSystemEntity a, FileSystemEntity b) {
    final aIsDir = a is Directory;
    final bIsDir = b is Directory;
    if (aIsDir && !bIsDir) return -1;
    if (!aIsDir && bIsDir) return 1;
    final aName = a.path.split(Platform.pathSeparator).last;
    final bName = b.path.split(Platform.pathSeparator).last;
    return aName.toLowerCase().compareTo(bName.toLowerCase());
  }

  void _openEntity(FileSystemEntity entity) {
    if (entity is Directory) {
      _navigateTo(entity);
    } else if (entity is File) {
      OpenFilex.open(entity.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final dirName = _currentDir?.path.split(Platform.pathSeparator).last ?? 'Files';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(dirName, style: TorrentFlowTheme.headline.copyWith(
          color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
        )),
        leading: _currentDir?.parent != _currentDir
            ? CupertinoNavigationBarBackButton(
                onPressed: () {
                  final parent = _currentDir?.parent;
                  if (parent != null) _navigateTo(parent);
                },
              )
            : null,
        backgroundColor: isDark
            ? TorrentFlowTheme.darkSurface.withValues(alpha: 0.85)
            : TorrentFlowTheme.lightSurface.withValues(alpha: 0.85),
        border: Border(bottom: BorderSide(
          color: isDark ? TorrentFlowTheme.darkSeparator : TorrentFlowTheme.lightSeparator,
          width: 0.5,
        )),
      ),
      child: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.folder_open, size: 48, color: TorrentFlowTheme.darkTextSecondary),
                      const SizedBox(height: 12),
                      Text('Empty directory', style: TorrentFlowTheme.body.copyWith(
                        color: TorrentFlowTheme.darkTextSecondary,
                      )),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => Container(
                    margin: const EdgeInsets.only(left: 52, right: TorrentFlowTheme.standardPadding),
                    height: 0.5,
                    color: isDark ? TorrentFlowTheme.darkSeparator : TorrentFlowTheme.lightSeparator,
                  ),
                  itemBuilder: (context, index) {
                    final entity = _entries[index];
                    final name = entity.path.split(Platform.pathSeparator).last;
                    final isDir = entity is Directory;
                    final stat = entity.statSync();
                    final size = isDir ? null : stat.size;

                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding, vertical: 8),
                      onPressed: () => _openEntity(entity),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: isDir
                                  ? TorrentFlowTheme.accent.withValues(alpha: 0.1)
                                  : TorrentFlowTheme.darkSurface3,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isDir ? CupertinoIcons.folder : _fileIcon(name),
                              size: 18,
                              color: isDir ? TorrentFlowTheme.accent : TorrentFlowTheme.darkTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: TorrentFlowTheme.body.copyWith(
                                  color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (size != null && size > 0)
                                  Text(_formatBytes(size), style: TorrentFlowTheme.footnote.copyWith(
                                    color: TorrentFlowTheme.darkTextSecondary,
                                  )),
                              ],
                            ),
                          ),
                          Icon(CupertinoIcons.chevron_forward, size: 14, color: TorrentFlowTheme.darkTextSecondary),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp4': case 'mov': case 'avi': case 'mkv':
        return CupertinoIcons.play_rectangle;
      case 'mp3': case 'wav': case 'aac': case 'flac':
        return CupertinoIcons.music_note;
      case 'jpg': case 'jpeg': case 'png': case 'gif':
        return CupertinoIcons.photo;
      case 'pdf':
        return CupertinoIcons.doc_text;
      case 'zip': case 'rar': case '7z':
        return CupertinoIcons.archivebox;
      default:
        return CupertinoIcons.doc;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
