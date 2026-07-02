import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/app_settings.dart';
import '../../../providers/settings/settings_providers.dart';
import '../../../core/native/native_service.dart';
import '../../files/presentation/file_browser_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Settings', style: TorrentFlowTheme.headline.copyWith(
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
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _SectionHeader(title: 'Appearance', isDark: isDark),
            _ThemeSelector(settings: settings, isDark: isDark),
            _SwitchTile(
              icon: CupertinoIcons.moon,
              title: 'Dark Mode',
              subtitle: 'Override system theme',
              value: settings.useDarkMode,
              enabled: !settings.followSystemTheme,
              onChanged: (v) => _updateSetting(ref, settings.copyWith(useDarkMode: v)),
            ),
            _SwitchTile(
              icon: CupertinoIcons.clock,
              title: 'Follow System Theme',
              value: settings.followSystemTheme,
              onChanged: (v) => _updateSetting(ref, settings.copyWith(followSystemTheme: v, useDarkMode: v ? true : settings.useDarkMode)),
            ),

            _SectionHeader(title: 'Downloads', isDark: isDark),
            _NavigationTile(
              icon: CupertinoIcons.folder,
              title: 'Download Location',
              subtitle: settings.defaultDownloadPath ?? 'Application Documents/Downloads/',
              onTap: () {},
              isDark: isDark,
            ),
            _StepperTile(
              icon: CupertinoIcons.arrow_down_circle,
              title: 'Max Concurrent Downloads',
              value: settings.maxConcurrentDownloads,
              min: 1,
              max: 10,
              onChanged: (v) => _updateSetting(ref, settings.copyWith(maxConcurrentDownloads: v)),
              isDark: isDark,
            ),
            _StepperTile(
              icon: CupertinoIcons.person_2,
              title: 'Max Peers per Torrent',
              value: settings.maxPeers,
              min: 10,
              max: 200,
              step: 10,
              onChanged: (v) => _updateSetting(ref, settings.copyWith(maxPeers: v)),
              isDark: isDark,
            ),
            _StepperTile(
              icon: CupertinoIcons.antenna_radiowaves_left_right,
              title: 'Max Connections',
              value: settings.maxConnections,
              min: 10,
              max: 200,
              step: 10,
              onChanged: (v) => _updateSetting(ref, settings.copyWith(maxConnections: v)),
              isDark: isDark,
            ),

            _SectionHeader(title: 'Speed', isDark: isDark),
            _SpeedTile(
              icon: CupertinoIcons.arrow_down,
              title: 'Download Limit',
              value: settings.downloadSpeedLimit,
              unit: 'KB/s',
              onChanged: (v) => _updateSetting(ref, settings.copyWith(downloadSpeedLimit: v)),
              isDark: isDark,
            ),
            _SpeedTile(
              icon: CupertinoIcons.arrow_up,
              title: 'Upload Limit',
              value: settings.uploadSpeedLimit,
              unit: 'KB/s',
              onChanged: (v) => _updateSetting(ref, settings.copyWith(uploadSpeedLimit: v)),
              isDark: isDark,
            ),

            _SectionHeader(title: 'Network', isDark: isDark),
            _SwitchTile(
              icon: CupertinoIcons.wifi,
              title: 'Wi-Fi Only',
              subtitle: 'Pause downloads on cellular',
              value: settings.wifiOnly,
              onChanged: (v) => _updateSetting(ref, settings.copyWith(wifiOnly: v)),
            ),
            _StepperTile(
              icon: CupertinoIcons.timer,
              title: 'Connection Timeout (s)',
              value: settings.connectionTimeout,
              min: 5,
              max: 60,
              step: 5,
              onChanged: (v) => _updateSetting(ref, settings.copyWith(connectionTimeout: v)),
              isDark: isDark,
            ),

            _SectionHeader(title: 'Notifications', isDark: isDark),
            _SwitchTile(
              icon: CupertinoIcons.bell,
              title: 'Notifications',
              subtitle: 'Download completed, errors',
              value: settings.notificationsEnabled,
              onChanged: (v) => _updateSetting(ref, settings.copyWith(notificationsEnabled: v)),
            ),

            _SectionHeader(title: 'Files', isDark: isDark),
            _NavigationTile(
              icon: CupertinoIcons.folder_open,
              title: 'File Browser',
              subtitle: 'Browse downloaded files',
              onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (_) => const FileBrowserScreen(),
                ));
              },
              isDark: isDark,
            ),

            _SectionHeader(title: 'Storage', isDark: isDark),
            _StorageInfo(isDark: isDark),

            _SectionHeader(title: 'About', isDark: isDark),
            _AboutTile(isDark: isDark),
          ],
        ),
      ),
    );
  }

  void _updateSetting(WidgetRef ref, AppSettings updated) {
    ref.read(settingsProvider.notifier).update(updated);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(TorrentFlowTheme.standardPadding, 20, TorrentFlowTheme.standardPadding, 4),
      child: Text(title.toUpperCase(), style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: TorrentFlowTheme.accent,
        letterSpacing: 0.5,
      )),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final AppSettings settings;
  final bool isDark;
  const _ThemeSelector({required this.settings, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding, vertical: 8),
      child: Row(
        children: [
          Icon(CupertinoIcons.paintbrush, size: 20, color: TorrentFlowTheme.darkTextSecondary),
          const SizedBox(width: 12),
          Text('Theme', style: TorrentFlowTheme.body.copyWith(
            color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
          )),
          const Spacer(),
          _ThemeButton(label: 'System', isSelected: settings.followSystemTheme, onTap: () {}),
          const SizedBox(width: 6),
          _ThemeButton(label: 'Light', isSelected: !settings.followSystemTheme && !settings.useDarkMode, onTap: () {}),
          const SizedBox(width: 6),
          _ThemeButton(label: 'Dark', isSelected: !settings.followSystemTheme && settings.useDarkMode, onTap: () {}),
        ],
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ThemeButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? TorrentFlowTheme.accent.withValues(alpha: 0.15) : null,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: TorrentFlowTheme.accent.withValues(alpha: 0.5)) : null,
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13,
          color: isSelected ? TorrentFlowTheme.accent : TorrentFlowTheme.darkTextSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        )),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: TorrentFlowTheme.darkTextSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TorrentFlowTheme.body.copyWith(
                  color: TorrentFlowTheme.darkText,
                )),
                if (subtitle != null)
                  Text(subtitle!, style: TorrentFlowTheme.footnote.copyWith(
                    color: TorrentFlowTheme.darkTextSecondary,
                  )),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: TorrentFlowTheme.accent,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _StepperTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _StepperTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: TorrentFlowTheme.darkTextSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: TorrentFlowTheme.body.copyWith(
              color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
            )),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(4),
            onPressed: value > min ? () => onChanged(value - step) : null,
            child: Icon(CupertinoIcons.minus_circle, size: 22, color: TorrentFlowTheme.darkTextSecondary),
          ),
          SizedBox(
            width: 40,
            child: Text('$value', textAlign: TextAlign.center, style: TorrentFlowTheme.body.copyWith(
              color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
              fontWeight: FontWeight.w600,
            )),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(4),
            onPressed: value < max ? () => onChanged(value + step) : null,
            child: Icon(CupertinoIcons.plus_circle, size: 22, color: TorrentFlowTheme.darkTextSecondary),
          ),
        ],
      ),
    );
  }
}

class _SpeedTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final String unit;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _SpeedTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final limitText = value == 0 ? 'Unlimited' : '$value $unit';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: TorrentFlowTheme.darkTextSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: TorrentFlowTheme.body.copyWith(
              color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
            )),
          ),
          Text(limitText, style: TorrentFlowTheme.body.copyWith(
            color: TorrentFlowTheme.accent,
            fontWeight: FontWeight.w500,
          )),
        ],
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _NavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding, vertical: 8),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: TorrentFlowTheme.darkTextSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TorrentFlowTheme.body.copyWith(
                  color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                )),
                Text(subtitle, style: TorrentFlowTheme.footnote.copyWith(
                  color: TorrentFlowTheme.darkTextSecondary,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_forward, size: 14, color: TorrentFlowTheme.darkTextSecondary),
        ],
      ),
    );
  }
}

class _StorageInfo extends StatelessWidget {
  final bool isDark;
  const _StorageInfo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: NativeTorrentService().getStorageInfo(),
      builder: (context, snapshot) {
        final info = snapshot.data ?? {};
        final free = _formatBytes((info['freeSpace'] as int?) ?? 0);
        final total = _formatBytes((info['totalSpace'] as int?) ?? 0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding, vertical: 8),
          child: Row(
            children: [
              Icon(CupertinoIcons.square_stack, size: 20, color: TorrentFlowTheme.darkTextSecondary),
              const SizedBox(width: 12),
              Text('Free Space', style: TorrentFlowTheme.body.copyWith(
                color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
              )),
              const Spacer(),
              Text('$free / $total', style: TorrentFlowTheme.body.copyWith(
                color: TorrentFlowTheme.darkTextSecondary,
              )),
            ],
          ),
        );
      },
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _AboutTile extends StatelessWidget {
  final bool isDark;
  const _AboutTile({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TorrentFlowTheme.standardPadding, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.info, size: 20, color: TorrentFlowTheme.darkTextSecondary),
              const SizedBox(width: 12),
              Text('TorrentFlow', style: TorrentFlowTheme.body.copyWith(
                color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
              )),
              const Spacer(),
              Text('v1.0.0', style: TorrentFlowTheme.body.copyWith(
                color: TorrentFlowTheme.darkTextSecondary,
              )),
            ],
          ),
          const SizedBox(height: 4),
          Text('A native iOS torrent downloader. No tracking, no ads, entirely offline except for BitTorrent networking.',
            style: TorrentFlowTheme.footnote.copyWith(color: TorrentFlowTheme.darkTextSecondary)),
        ],
      ),
    );
  }
}

extension on AppSettings {
  String? get defaultDownloadPath => null;
}
