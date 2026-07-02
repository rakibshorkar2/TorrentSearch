import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/seedr_item.dart';
import '../../../providers/seedr/seedr_providers.dart';
import '../../../providers/downloads/download_providers.dart';

class SeedrScreen extends ConsumerStatefulWidget {
  const SeedrScreen({super.key});

  @override
  ConsumerState<SeedrScreen> createState() => _SeedrScreenState();
}

class _SeedrScreenState extends ConsumerState<SeedrScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _labelController = TextEditingController();
  bool _isLoggingIn = false;
  bool _isLoggedIn = false;
  bool _isLoadingContents = false;
  String? _error;
  List<SeedrItem> _items = [];
  SeedrItem? _currentFolder;
  int _activeAccountIndex = 0;
  bool _showAccountManager = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final accounts = ref.read(seedrAccountsProvider);
    if (accounts.isNotEmpty) {
      _activeAccountIndex = ref.read(seedrAccountsProvider.notifier).activeAccountIndex;
      final active = accounts[_activeAccountIndex.clamp(0, accounts.length - 1)];
      if (active.isLoggedIn) {
        setState(() => _isLoggedIn = true);
        _loadContents();
      }
    } else {
      final service = ref.read(seedrServiceProvider);
      final loggedIn = await service.isLoggedIn();
      if (mounted) {
        setState(() => _isLoggedIn = loggedIn);
        if (loggedIn) _loadContents();
      }
    }
  }

  Future<void> _loadContents({int? folderId}) async {
    setState(() {
      _isLoadingContents = true;
      _error = null;
    });
    try {
      final service = ref.read(seedrServiceProvider);
      final items = await service.listContents(folderId: folderId);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoadingContents = false;
          _currentFolder = folderId != null
              ? SeedrItem(id: folderId.toString(), name: 'Folder', size: 0, type: SeedrItemType.folder)
              : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingContents = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final accounts = ref.watch(seedrAccountsProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_currentFolder?.name ?? 'Seedr', style: TorrentFlowTheme.headline.copyWith(
          color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
        )),
        backgroundColor: isDark
            ? TorrentFlowTheme.darkSurface.withValues(alpha: 0.85)
            : TorrentFlowTheme.lightSurface.withValues(alpha: 0.85),
        border: Border(bottom: BorderSide(
          color: isDark ? TorrentFlowTheme.darkSeparator : TorrentFlowTheme.lightSeparator,
          width: 0.5,
        )),
        leading: _currentFolder != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _loadContents(),
                child: Icon(CupertinoIcons.chevron_left, color: TorrentFlowTheme.accent),
              )
            : null,
        trailing: _isLoggedIn
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _showAccountManager = !_showAccountManager),
                child: Icon(CupertinoIcons.person_circle, color: TorrentFlowTheme.accent),
              )
            : null,
      ),
      child: SafeArea(
        child: _showAccountManager && _isLoggedIn
            ? _buildAccountManagerView(isDark, accounts)
            : (_isLoggedIn ? _buildContentView(isDark) : _buildLoginView(isDark)),
      ),
    );
  }

  Widget _buildAccountManagerView(bool isDark, List<SeedrAccountState> accounts) {
    return ListView(
      padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: TorrentFlowTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(CupertinoIcons.person_3, size: 40, color: TorrentFlowTheme.accent),
          ),
        ),
        const SizedBox(height: 24),
        Text('Account Manager', style: TorrentFlowTheme.title2.copyWith(
          color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
        ), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ...List.generate(accounts.length, (i) {
          final account = accounts[i];
          final isActive = i == _activeAccountIndex;
          return GestureDetector(
            onTap: account.isLoggedIn ? () => _switchToAccount(i) : null,
            child: GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.person_crop_circle,
                        color: account.isLoggedIn ? TorrentFlowTheme.success : TorrentFlowTheme.darkTextSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(account.label ?? account.email,
                                  style: TorrentFlowTheme.callout.copyWith(
                                    color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                                  )),
                                if (isActive) ...[
                                  const SizedBox(width: 6),
                                  Icon(CupertinoIcons.checkmark_circle_fill, color: TorrentFlowTheme.accent, size: 14),
                                ],
                              ],
                            ),
                            Text(account.email,
                              style: TorrentFlowTheme.caption1.copyWith(
                                color: TorrentFlowTheme.darkTextSecondary,
                              )),
                          ],
                        ),
                      ),
                      if (account.isLoggedIn && !isActive)
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          onPressed: () => _switchToAccount(i),
                          child: Text('Switch', style: TextStyle(fontSize: 13, color: TorrentFlowTheme.accent)),
                        ),
                    ],
                  ),
                  if (account.account != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: isDark ? TorrentFlowTheme.darkSurface3 : TorrentFlowTheme.lightSurface2,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: account.account!.usagePercent.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: TorrentFlowTheme.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${account.account!.formattedUsed} / ${account.account!.formattedTotal}',
                      style: TorrentFlowTheme.caption2.copyWith(color: TorrentFlowTheme.darkTextSecondary)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (account.isLoggedIn)
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: () => _logoutAccount(i),
                          child: Text('Logout', style: TextStyle(fontSize: 13, color: TorrentFlowTheme.error)),
                        ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        onPressed: () => _removeAccount(i),
                        child: Text('Remove', style: const TextStyle(fontSize: 13, color: TorrentFlowTheme.error)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        CupertinoButton.filled(
          onPressed: _showAddAccountDialog,
          child: const Text('Add Account'),
        ),
        CupertinoButton(
          onPressed: () => setState(() => _showAccountManager = false),
          child: const Text('Back to Files'),
        ),
      ],
    );
  }

  Widget _buildLoginView(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: TorrentFlowTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(CupertinoIcons.cloud, size: 40, color: TorrentFlowTheme.accent),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text('Seedr Cloud', style: TorrentFlowTheme.title2.copyWith(
            color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
          )),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('Access your Seedr account', style: TorrentFlowTheme.subheadline.copyWith(
            color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
          )),
        ),
        const SizedBox(height: 32),
        GlassCard(
          child: Column(
            children: [
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: TorrentFlowTheme.body.copyWith(
                  color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                ),
                placeholderStyle: TorrentFlowTheme.body.copyWith(
                  color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: null,
              ),
              Container(height: 1,
                color: isDark ? TorrentFlowTheme.darkSeparator : TorrentFlowTheme.lightSeparator),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Password',
                obscureText: true,
                style: TorrentFlowTheme.body.copyWith(
                  color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                ),
                placeholderStyle: TorrentFlowTheme.body.copyWith(
                  color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CupertinoButton.filled(
          onPressed: _isLoggingIn ? null : _login,
          child: _isLoggingIn
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : const Text('Log In'),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text('Don\'t have an account? Sign up at seedr.cc',
            style: TorrentFlowTheme.footnote.copyWith(
              color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
            )),
        ),
      ],
    );
  }

  Widget _buildContentView(bool isDark) {
    if (_isLoadingContents) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: TorrentFlowTheme.error),
            const SizedBox(height: 12),
            Text(_error!, style: TorrentFlowTheme.body.copyWith(color: TorrentFlowTheme.error)),
            const SizedBox(height: 16),
            CupertinoButton(onPressed: _loadContents, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.cloud, size: 48,
              color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
            const SizedBox(height: 12),
            Text('No files in Seedr', style: TorrentFlowTheme.body.copyWith(
              color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary)),
            const SizedBox(height: 16),
            CupertinoButton(onPressed: _loadContents, child: const Text('Refresh')),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
      itemCount: _items.length,
      separatorBuilder: (context, index) => const SizedBox(height: TorrentFlowTheme.spacing),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _SeedrItemCard(
          item: item,
          isDark: isDark,
          onTap: () {
            if (item.isFolder) {
              _loadContents(folderId: int.tryParse(item.id));
            } else if (item.type == SeedrItemType.torrent && item.downloadUrl != null) {
              _showSeedrItemOptions(item, isDark);
            }
          },
          onDownload: () => _downloadFromSeedr(item),
          onDelete: () => _deleteSeedrItem(item),
        );
      },
    );
  }

  void _showSeedrItemOptions(SeedrItem item, bool isDark) {
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
            Center(child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: TorrentFlowTheme.darkTextSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(item.name, style: TorrentFlowTheme.title3, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            _MenuButton(icon: CupertinoIcons.arrow_down_circle, label: 'Download to Device',
              onTap: () { Navigator.of(ctx).pop(); _downloadFromSeedr(item); }),
            _MenuButton(icon: CupertinoIcons.play_circle, label: 'Stream',
              onTap: () { Navigator.of(ctx).pop(); _streamSeedrItem(item); }),
            _MenuButton(icon: CupertinoIcons.trash, label: 'Delete', isDestructive: true,
              onTap: () { Navigator.of(ctx).pop(); _deleteSeedrItem(item); }),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFromSeedr(SeedrItem item) async {
    if (item.downloadUrl == null) return;
    try {
      final bgService = ref.read(backgroundDownloadServiceProvider);
      await bgService.downloadFromSeedr(
        title: item.name,
        url: item.downloadUrl!,
        destination: '/downloads/seedr/${item.name}',
      );
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Icon(CupertinoIcons.checkmark_circle, color: TorrentFlowTheme.success, size: 40),
            content: const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Download started'),
            ),
            actions: [CupertinoButton(child: const Text('OK'), onPressed: () => Navigator.of(ctx).pop())],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Download Failed'),
            content: Text(e.toString()),
            actions: [CupertinoButton(child: const Text('OK'), onPressed: () => Navigator.of(ctx).pop())],
          ),
        );
      }
    }
  }

  void _streamSeedrItem(SeedrItem item) {
    if (item.streamUrl == null) return;
    HapticFeedback.lightImpact();
    // TODO: Integrate AVPlayer for streaming
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Stream'),
        content: Text('Streaming not yet integrated. URL: ${item.streamUrl}'),
        actions: [CupertinoButton(child: const Text('OK'), onPressed: () => Navigator.of(ctx).pop())],
      ),
    );
  }

  Future<void> _deleteSeedrItem(SeedrItem item) async {
    try {
      final service = ref.read(seedrServiceProvider);
      final type = item.type == SeedrItemType.folder ? 'folder' : 'torrent';
      await service.deleteItem(type, item.id);
      _loadContents();
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Delete Failed'),
            content: Text(e.toString()),
            actions: [CupertinoButton(child: const Text('OK'), onPressed: () => Navigator.of(ctx).pop())],
          ),
        );
      }
    }
  }

  Future<void> _logoutAccount(int index) async {
    final notifier = ref.read(seedrAccountsProvider.notifier);
    await notifier.logoutAccount(index);
    if (mounted) setState(() => _showAccountManager = false);
  }

  Future<void> _removeAccount(int index) async {
    final notifier = ref.read(seedrAccountsProvider.notifier);
    await notifier.removeAccount(index);
    if (index == _activeAccountIndex && _activeAccountIndex >= ref.read(seedrAccountsProvider).length) {
      _activeAccountIndex = ref.read(seedrAccountsProvider).length - 1;
    }
  }

  Future<void> _switchToAccount(int index) async {
    final notifier = ref.read(seedrAccountsProvider.notifier);
    await notifier.switchAccount(index);
    if (mounted) {
      setState(() {
        _activeAccountIndex = index;
        _isLoggedIn = true;
        _items = [];
      });
      _loadContents();
    }
  }

  void _showAddAccountDialog() {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Add Seedr Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: emailCtrl,
              placeholder: 'Email',
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: passwordCtrl,
              placeholder: 'Password',
              obscureText: true,
            ),
          ],
        ),
        actions: [
          CupertinoButton(
            child: const Text('Cancel'),
            onPressed: () {
              emailCtrl.dispose();
              passwordCtrl.dispose();
              Navigator.of(ctx).pop();
            },
          ),
          CupertinoButton(
            child: const Text('Add'),
            onPressed: () async {
              if (emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                final notifier = ref.read(seedrAccountsProvider.notifier);
                await notifier.addAccount(emailCtrl.text, passwordCtrl.text);
                if (mounted) {
                  setState(() {
                    _isLoggedIn = true;
                    _activeAccountIndex = ref.read(seedrAccountsProvider).length - 1;
                    _showAccountManager = false;
                  });
                  _loadContents();
                }
              } catch (e) {
                if (mounted) {
                  showCupertinoDialog(
                    context: context,
                    builder: (ctx2) => CupertinoAlertDialog(
                      title: const Text('Login Failed'),
                      content: Text(e.toString()),
                      actions: [CupertinoButton(child: const Text('OK'), onPressed: () => Navigator.of(ctx2).pop())],
                    ),
                  );
                }
              } finally {
                emailCtrl.dispose();
                passwordCtrl.dispose();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoggingIn = true);
    try {
      final notifier = ref.read(seedrAccountsProvider.notifier);
      await notifier.addAccount(_emailController.text, _passwordController.text);
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _isLoggingIn = false;
          _activeAccountIndex = ref.read(seedrAccountsProvider).length - 1;
        });
        _loadContents();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoggingIn = false);
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Login Failed'),
            content: Text(e.toString()),
            actions: [
              CupertinoButton(child: const Text('OK'), onPressed: () => Navigator.of(ctx).pop()),
            ],
          ),
        );
      }
    }
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

class _SeedrItemCard extends StatelessWidget {
  final SeedrItem item;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _SeedrItemCard({
    required this.item,
    required this.isDark,
    required this.onTap,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _iconColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon(), size: 20, color: _iconColor()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: TorrentFlowTheme.callout.copyWith(
                  color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (item.fileCount > 0)
                      Text('${item.fileCount} files', style: TorrentFlowTheme.caption2.copyWith(color: TorrentFlowTheme.darkTextSecondary)),
                    if (item.type == SeedrItemType.torrent) ...[
                      Text(item.formattedProgress, style: TorrentFlowTheme.caption2.copyWith(
                        color: item.progress >= 100 ? TorrentFlowTheme.success : TorrentFlowTheme.warning,
                      )),
                      const SizedBox(width: 8),
                    ],
                    Text(item.formattedSize, style: TorrentFlowTheme.caption2.copyWith(color: TorrentFlowTheme.darkTextSecondary)),
                  ],
                ),
              ],
            ),
          ),
          if (item.type == SeedrItemType.torrent && (item.progress >= 100))
            CupertinoButton(
              padding: const EdgeInsets.all(4),
              onPressed: onDownload,
              child: Icon(CupertinoIcons.arrow_down_circle, size: 20, color: TorrentFlowTheme.accent),
            ),
          CupertinoButton(
            padding: const EdgeInsets.all(4),
            onPressed: onDelete,
            child: Icon(CupertinoIcons.trash, size: 16, color: TorrentFlowTheme.error),
          ),
        ],
      ),
    );
  }

  IconData _icon() {
    switch (item.type) {
      case SeedrItemType.folder: return CupertinoIcons.folder;
      case SeedrItemType.file: return CupertinoIcons.doc;
      case SeedrItemType.torrent:
        return item.progress >= 100 ? CupertinoIcons.checkmark_circle : CupertinoIcons.arrow_down_circle;
    }
  }

  Color _iconColor() {
    switch (item.type) {
      case SeedrItemType.folder: return TorrentFlowTheme.warning;
      case SeedrItemType.file: return TorrentFlowTheme.accent;
      case SeedrItemType.torrent:
        return item.progress >= 100 ? TorrentFlowTheme.success : TorrentFlowTheme.accent;
    }
  }
}
