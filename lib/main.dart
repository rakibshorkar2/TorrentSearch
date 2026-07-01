import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/app_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      ref.read(backgroundDownloadServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const TorrentFlowApp();
  }
}
