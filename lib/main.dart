import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/native/native_service.dart';
import 'providers/downloads/download_providers.dart';
import 'services/storage_service.dart';
import 'services/history_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  runZonedGuarded(() async {
    final storage = StorageService();
    await storage.init();

    final historyService = HistoryService();
    await historyService.init();

    runApp(
      const ProviderScope(
        child: TorrentFlowAppStartup(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}

class TorrentFlowAppStartup extends ConsumerStatefulWidget {
  const TorrentFlowAppStartup({super.key});

  @override
  ConsumerState<TorrentFlowAppStartup> createState() => _TorrentFlowAppStartupState();
}

class _TorrentFlowAppStartupState extends ConsumerState<TorrentFlowAppStartup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bgService = ref.read(backgroundDownloadServiceProvider);
      NativeTorrentService().initialize(
        onBackgroundDownloadComplete: bgService.handleBackgroundDownloadComplete,
      );
      bgService.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const TorrentFlowApp();
  }
}
