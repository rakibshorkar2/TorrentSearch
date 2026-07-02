import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/native/native_service.dart';
import 'core/constants/app_constants.dart';
import 'providers/downloads/download_providers.dart';
import 'services/storage_service.dart';
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
  String? storageError;

  try {
    final storage = StorageService();
    await storage.init().timeout(const Duration(seconds: 5));
    storageInitialized = true;
  } catch (e, st) {
    storageError = e.toString();
    appLogger.e('StorageService init failed or timed out', error: e, stackTrace: st);
  }

  runZonedGuarded(() {
    runApp(
      ProviderScope(
        child: TorrentFlowAppStartup(
          storageReady: storageInitialized,
          storageError: storageError,
        ),
      ),
    );
  }, (error, stack) {
    appLogger.e('Uncaught error', error: error, stackTrace: stack);
  });
}

class TorrentFlowAppStartup extends ConsumerStatefulWidget {
  final bool storageReady;
  final String? storageError;

  const TorrentFlowAppStartup({
    super.key,
    required this.storageReady,
    this.storageError,
  });

  @override
  ConsumerState<TorrentFlowAppStartup> createState() => _TorrentFlowAppStartupState();
}

class _TorrentFlowAppStartupState extends ConsumerState<TorrentFlowAppStartup> {
  late bool _storageReady;
  String? _storageError;
  bool _initializing = false;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _storageReady = widget.storageReady;
    _storageError = widget.storageError;

    if (_storageReady) {
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
    String? storageErr;

    try {
      final storage = StorageService();
      await storage.init().timeout(const Duration(seconds: 5));
      storageOk = true;
    } catch (e, st) {
      storageErr = e.toString();
      appLogger.e('Retry StorageService init failed', error: e, stackTrace: st);
    }

    if (mounted) {
      setState(() {
        _storageReady = storageOk;
        _storageError = storageErr;
        _initializing = false;
      });

      if (storageOk) {
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
    } catch (e) {
      appLogger.e('Failed to delete boxes from disk', error: e);
    }

    await _retryInit();
  }

  @override
  Widget build(BuildContext context) {
    if (!_storageReady) {
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
                    const Text(
                      'TorrentFlow failed to load its local database.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showDetails = !_showDetails;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showDetails ? 'Hide Error Details' : 'Show Error Details',
                            style: const TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.systemBlue,
                            ),
                          ),
                          Icon(
                            _showDetails ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                            size: 14,
                            color: CupertinoColors.systemBlue,
                          ),
                        ],
                      ),
                    ),
                    if (_showDetails) ...[
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF38383A)),
                        ),
                        child: SingleChildScrollView(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _storageError != null ? 'Storage: $_storageError' : '',
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 12,
                                color: Color(0xFFFF453A),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                        child: const Text(
                          'Retry Initialization',
                          style: TextStyle(color: CupertinoColors.white),
                        ),
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
