import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/app_settings.dart';
import '../../../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final surfaceColor = isDark ? TorrentFlowTheme.darkSurface.withValues(alpha: 0.85) : TorrentFlowTheme.lightSurface.withValues(alpha: 0.85);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Settings', style: TorrentFlowTheme.headline.copyWith(
          color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
        )),
        backgroundColor: surfaceColor,
        border: Border(bottom: BorderSide(
          color: isDark ? TorrentFlowTheme.darkSeparator : TorrentFlowTheme.lightSeparator,
          width: 0.5,
        )),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: TorrentFlowTheme.tightPadding),
          children: [
            _SectionHeader(title: 'General', isDark: isDark),
            _SettingsGroup(children: [
              _SettingTile(
                icon: CupertinoIcons.moon_stars,
                title: 'Dark Mode',
                trailing: CupertinoSwitch(
                  value: settings.useDarkMode,
                  onChanged: (v) => ref.read(settingsProvider.notifier).update(
                    settings.copyWith(useDarkMode: v),
                  ),
                ),
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: CupertinoIcons.arrow_up_arrow_down,
                title: 'Follow System Theme',
                trailing: CupertinoSwitch(
                  value: settings.followSystemTheme,
                  onChanged: (v) => ref.read(settingsProvider.notifier).update(
                    settings.copyWith(followSystemTheme: v),
                  ),
                ),
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: CupertinoIcons.link,
                title: 'Auto-Import Magnets',
                subtitle: 'Automatically add magnet links from clipboard',
                trailing: CupertinoSwitch(
                  value: settings.autoImportMagnet,
                  onChanged: (v) => ref.read(settingsProvider.notifier).update(
                    settings.copyWith(autoImportMagnet: v),
                  ),
                ),
                isDark: isDark,
              ),
            ]),
            _SectionHeader(title: 'Downloads', isDark: isDark),
            _SettingsGroup(children: [
              _SettingTile(
                icon: CupertinoIcons.arrow_down_circle,
                title: 'Max Concurrent',
                subtitle: '${settings.maxConcurrentDownloads} downloads',
                onTap: () => _showPicker(context, ref, settings, 'concurrent'),
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: CupertinoIcons.person_2,
                title: 'Max Peers',
                subtitle: '${settings.maxPeers} peers',
                onTap: () => _showPicker(context, ref, settings, 'peers'),
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: CupertinoIcons.speedometer,
                title: 'Download Limit',
                subtitle: settings.downloadSpeedLimit > 0
                    ? '${settings.downloadSpeedLimit} KB/s'
                    : 'Unlimited',
                onTap: () => _showSpeedDialog(context, ref, settings, 'download'),
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: CupertinoIcons.speedometer,
                title: 'Upload Limit',
                subtitle: settings.uploadSpeedLimit > 0
                    ? '${settings.uploadSpeedLimit} KB/s'
                    : 'Unlimited',
                onTap: () => _showSpeedDialog(context, ref, settings, 'upload'),
                isDark: isDark,
              ),
            ]),
            _SectionHeader(title: 'Network', isDark: isDark),
            _SettingsGroup(children: [
              _SettingTile(
                icon: CupertinoIcons.wifi,
                title: 'Wi-Fi Only',
                trailing: CupertinoSwitch(
                  value: settings.wifiOnly,
                  onChanged: (v) => ref.read(settingsProvider.notifier).update(
                    settings.copyWith(wifiOnly: v),
                  ),
                ),
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: CupertinoIcons.shield,
                title: 'SOCKS5 Proxy',
                subtitle: settings.socks5ProxyHost != null
                    ? '${settings.socks5ProxyHost}:${settings.socks5ProxyPort}'
                    : 'Disabled',
                onTap: () => _showProxyDialog(context, ref, settings),
                isDark: isDark,
              ),
            ]),
            _SectionHeader(title: 'About', isDark: isDark),
            _SettingsGroup(children: [
              _SettingTile(
                icon: CupertinoIcons.info_circle,
                title: 'Version',
                subtitle: '${AppConstants.appVersion} (${AppConstants.appBuild})',
                isDark: isDark,
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref, AppSettings settings, String type) {
    final items = switch (type) {
      'concurrent' => [1, 2, 3, 5, 10],
      'peers' => [20, 50, 100, 200, 500],
      _ => [],
    };
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: CupertinoTheme.brightnessOf(context) == Brightness.dark
            ? TorrentFlowTheme.darkSurface : TorrentFlowTheme.lightSurface,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                  Text('Select', style: TorrentFlowTheme.headline),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                onSelectedItemChanged: (i) {
                  final value = items[i];
                  ref.read(settingsProvider.notifier).update(switch (type) {
                    'concurrent' => settings.copyWith(maxConcurrentDownloads: value),
                    'peers' => settings.copyWith(maxPeers: value),
                    _ => settings,
                  });
                },
                children: items.map((v) => Center(
                  child: Text('$v', style: TorrentFlowTheme.body.copyWith(
                    color: CupertinoTheme.brightnessOf(context) == Brightness.dark
                        ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                  )),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedDialog(BuildContext context, WidgetRef ref, AppSettings settings, String type) {
    final controller = TextEditingController(
      text: type == 'download'
          ? '${settings.downloadSpeedLimit}'
          : '${settings.uploadSpeedLimit}',
    );
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('${type == 'download' ? 'Download' : 'Upload'} Speed Limit'),
        content: CupertinoTextField(
          controller: controller,
          placeholder: 'Speed in KB/s (0 = unlimited)',
          keyboardType: TextInputType.number,
        ),
        actions: [
          CupertinoButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoButton(
            child: const Text('Save'),
            onPressed: () {
              final value = int.tryParse(controller.text) ?? 0;
              ref.read(settingsProvider.notifier).update(type == 'download'
                  ? settings.copyWith(downloadSpeedLimit: value)
                  : settings.copyWith(uploadSpeedLimit: value));
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showProxyDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final hostCtrl = TextEditingController(text: settings.socks5ProxyHost ?? '');
    final portCtrl = TextEditingController(
      text: settings.socks5ProxyPort?.toString() ?? '',
    );
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('SOCKS5 Proxy'),
        content: Column(
          children: [
            CupertinoTextField(
              controller: hostCtrl,
              placeholder: 'Host (e.g. 127.0.0.1)',
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: portCtrl,
              placeholder: 'Port (e.g. 1080)',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          CupertinoButton(
            child: const Text('Clear'),
            onPressed: () {
              ref.read(settingsProvider.notifier).update(settings.copyWith(
                socks5ProxyHost: null,
                socks5ProxyPort: null,
              ));
              Navigator.of(ctx).pop();
            },
          ),
          CupertinoButton(
            child: const Text('Save'),
            onPressed: () {
              final host = hostCtrl.text.isNotEmpty ? hostCtrl.text : null;
              final port = int.tryParse(portCtrl.text);
              ref.read(settingsProvider.notifier).update(settings.copyWith(
                socks5ProxyHost: host,
                socks5ProxyPort: port,
              ));
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: TorrentFlowTheme.standardPadding,
        right: TorrentFlowTheme.standardPadding,
        top: 24,
        bottom: 6,
      ),
      child: Text(title, style: TorrentFlowTheme.footnote.copyWith(
        color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      )),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding),
      decoration: BoxDecoration(
        color: isDark ? TorrentFlowTheme.darkSurface2 : TorrentFlowTheme.lightSurface,
        borderRadius: BorderRadius.circular(TorrentFlowTheme.cornerRadius),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDark;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onPressed: onTap,
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: TorrentFlowTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 16, color: TorrentFlowTheme.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TorrentFlowTheme.body.copyWith(
                  color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                )),
                if (subtitle != null)
                  Text(subtitle!, style: TorrentFlowTheme.footnote.copyWith(
                    color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                  )),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (onTap != null && trailing == null)
            Icon(CupertinoIcons.chevron_forward, size: 14,
              color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 54),
      height: 0.5,
      color: isDark ? TorrentFlowTheme.darkSeparator : TorrentFlowTheme.lightSeparator,
    );
  }
}
