import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/native/native_service.dart';
import 'core/constants/app_constants.dart';
import 'providers/downloads/download_providers.dart';
import 'services/storage_service.dart';
import 'services/history_service.dart';
import 'logging/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    appLogger.e('Flutter error', error: details.exception, stackTrace: details.stack);
  };

  ErrorWidget.builder = (details) {
    return Container(
      color: const Color(0xFF1C1C1E),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'Error: ${details.exception}',
          style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 14),
        ),
      ),
    );
  };

  bool storageInitialized = false;
  bool historyInitialized = false;

  try {
    final storage = StorageService();
    await storage.init().timeout(const Duration(seconds: 5));
    storageInitialized = true;
  } catch (e, st) {
    appLogger.e('StorageService init failed or timed out', error: e, stackTrace: st);
  }

  try {
    final historyService = HistoryService();
    await historyService.init().timeout(const Duration(seconds: 5));
    historyInitialized = true;
  } catch (e, st) {
    appLogger.e('HistoryService init failed or timed out', error: e, stackTrace: st);
  }

  runZonedGuarded(() {
    runApp(
      ProviderScope(
        child: TorrentFlowAppStartup(
          storageReady: storageInitialized,
          historyReady: historyInitialized,
        ),
      ),
    );
  }, (error, stack) {
    appLogger.e('Uncaught error', error: error, stackTrace: stack);
  });
}

class TorrentFlowAppStartup extends ConsumerStatefulWidget {
  final bool storageReady;
  final bool historyReady;

  const TorrentFlowAppStartup({
    super.key,
    required this.storageReady,
    required this.historyReady,
  });

  @override
  ConsumerState<TorrentFlowAppStartup> createState() => _TorrentFlowAppStartupState();
}

class _TorrentFlowAppStartupState extends ConsumerState<TorrentFlowAppStartup> {
  late bool _storageReady;
  late bool _historyReady;
  bool _initializing = false;

  @override
  void initState() {
    super.initState();
    _storageReady = widget.storageReady;
    _historyReady = widget.historyReady;

    if (_storageReady && _historyReady) {
      _initServices();
    }
  }

  void _initServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bgService = ref.read(backgroundDownloadServiceProvider);
      NativeTorrentService().initialize(
        onBackgroundDownloadComplete: bgService.handleBackgroundDownloadComplete,
      );
      bgService.initialize();
    });
  }

  Future<void> _retryInit() async {
    setState(() {
      _initializing = true;
    });

    bool storageOk = false;
    bool historyOk = false;

    try {
      final storage = StorageService();
      await storage.init().timeout(const Duration(seconds: 5));
      storageOk = true;
    } catch (e, st) {
      appLogger.e('Retry StorageService init failed', error: e, stackTrace: st);
    }

    try {
      final historyService = HistoryService();
      await historyService.init().timeout(const Duration(seconds: 5));
      historyOk = true;
    } catch (e, st) {
      appLogger.e('Retry HistoryService init failed', error: e, stackTrace: st);
    }

    if (mounted) {
      setState(() {
        _storageReady = storageOk;
        _historyReady = historyOk;
        _initializing = false;
      });

      if (storageOk && historyOk) {
        _initServices();
      }
    }
  }

  Future<void> _resetAndRetry() async {
    setState(() {
      _initializing = true;
    });

    try {
      await Hive.deleteBoxFromDisk(AppConstants.hiveBoxSettings);
      await Hive.deleteBoxFromDisk(AppConstants.hiveBoxDownloads);
      await Hive.deleteBoxFromDisk(AppConstants.hiveBoxSearchHistory);
      await Hive.deleteBoxFromDisk(AppConstants.hiveBoxSeedrCache);
      await Hive.deleteBoxFromDisk(AppConstants.hiveBoxHistory);
    } catch (e) {
      appLogger.e('Failed to delete boxes from disk', error: e);
    }

    await _retryInit();
  }

  @override
  Widget build(BuildContext context) {
    if (!_storageReady || !_historyReady) {
      return CupertinoApp(
        debugShowCheckedModeBanner: false,
        theme: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: CupertinoColors.systemBlue,
          scaffoldBackgroundColor: Color(0xFF000000),
        ),
        home: CupertinoPageScaffold(
          backgroundColor: const Color(0xFF000000),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_shield_fill,
                      color: CupertinoColors.systemRed,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Storage Initialization Failed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'TorrentFlow failed to load its local databases. This can happen if files are corrupted or locked.\n\nFailed components: ${[
                        if (!_storageReady) 'Main Storage',
                        if (!_historyReady) 'History Database'
                      ].join(', ')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_initializing)
                      const Center(
                        child: CupertinoActivityIndicator(radius: 12),
                      )
                    else ...[
                      CupertinoButton(
                        color: CupertinoColors.systemBlue,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _retryInit,
                        child: const Text('Retry Initialization'),
                      ),
                      const SizedBox(height: 12),
                      CupertinoButton(
                        color: const Color(0x33FF3B30),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _resetAndRetry,
                        child: const Text(
                          'Reset Databases (Deletes Data)',
                          style: TextStyle(color: CupertinoColors.systemRed),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return const TorrentFlowApp();
  }
}
