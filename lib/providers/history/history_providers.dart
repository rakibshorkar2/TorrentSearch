import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/history_item.dart';
import '../../services/history_service.dart';
import '../../logging/app_logger.dart';

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService();
});

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryItem>>((ref) {
  return HistoryNotifier(ref.read(historyServiceProvider));
});

class HistoryNotifier extends StateNotifier<List<HistoryItem>> {
  final HistoryService _service;
  bool _disposed = false;

  HistoryNotifier(this._service) : super([]) {
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await _service.loadAll();
      if (_disposed) return;
      state = items;
    } catch (e) {
      appLogger.e('Failed to load history', error: e);
    }
  }

  Future<void> addMagnetLink({
    required String title,
    required String magnetUri,
    String? infoHash,
    int? totalSize,
  }) async {
    final item = HistoryItem(
      id: 'magnet_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      magnetUri: magnetUri,
      infoHash: infoHash,
      totalSize: totalSize,
      type: HistoryItemType.magnetLink,
      addedAt: DateTime.now(),
    );
    state = [item, ...state];
    await _service.addItem(item);
  }

  Future<void> addDownload({
    required String title,
    required String magnetUri,
    String? infoHash,
    int? totalSize,
  }) async {
    final item = HistoryItem(
      id: 'dl_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      magnetUri: magnetUri,
      infoHash: infoHash,
      totalSize: totalSize,
      type: HistoryItemType.download,
      addedAt: DateTime.now(),
    );
    state = [item, ...state];
    await _service.addItem(item);
  }

  Future<void> markCompleted(String id) async {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(completedAt: DateTime.now(), downloadCompleted: true)
        else
          item,
    ];
    await _service.saveAll(state);
  }

  Future<void> removeItem(String id) async {
    state = state.where((i) => i.id != id).toList();
    await _service.removeItem(id);
  }

  Future<void> clearMagnetLinks() async {
    state = state.where((i) => i.type != HistoryItemType.magnetLink).toList();
    await _service.clearMagnetLinks();
  }

  Future<void> clearDownloads() async {
    state = state.where((i) => i.type != HistoryItemType.download).toList();
    await _service.clearDownloads();
  }

  Future<void> clearAll() async {
    state = [];
    await _service.clearAll();
  }
}
