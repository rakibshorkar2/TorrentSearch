import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/cupertino_theme.dart';
import 'providers/settings/settings_providers.dart';
import 'features/search/presentation/search_screen.dart';
import 'features/downloads/presentation/downloads_screen.dart';
import 'features/seedr/presentation/seedr_screen.dart';
import 'features/settings/presentation/settings_screen.dart';

class TorrentFlowApp extends ConsumerWidget {
  const TorrentFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    ref.watch(screenAwakeProvider);
    final isDark = settings.followSystemTheme
        ? PlatformDispatcher.instance.platformBrightness == Brightness.dark
        : settings.useDarkMode;
    final theme = isDark
        ? TorrentFlowCupertinoTheme.darkTheme()
        : TorrentFlowCupertinoTheme.lightTheme();

    TorrentFlowTheme.configureStatusBar();

    return CupertinoApp(
      title: 'TorrentFlow',
      theme: theme,
      home: const MainShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    SearchScreen(),
    DownloadsScreen(),
    SeedrScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        activeColor: TorrentFlowTheme.accent,
        inactiveColor: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.color ?? TorrentFlowTheme.darkTextSecondary,
        backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
        border: Border(
          top: BorderSide(
            color: CupertinoTheme.brightnessOf(context) == Brightness.dark
                ? TorrentFlowTheme.darkSeparator
                : TorrentFlowTheme.lightSeparator,
            width: 0.5,
          ),
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.search),
            activeIcon: Icon(CupertinoIcons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.arrow_down_circle),
            activeIcon: Icon(CupertinoIcons.arrow_down_circle_fill),
            label: 'Downloads',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.cloud),
            activeIcon: Icon(CupertinoIcons.cloud_fill),
            label: 'Seedr',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            activeIcon: Icon(CupertinoIcons.settings_solid),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) => _screens[index],
        );
      },
    );
  }
}
