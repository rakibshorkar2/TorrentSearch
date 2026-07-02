import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/native/native_service.dart';
import 'providers/downloads/download_providers.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  await storage.init();

  runApp(
    const ProviderScope(
      child: TorrentFlowAppStartup(),
    ),
  );
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
