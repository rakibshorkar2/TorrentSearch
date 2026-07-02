import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/history_item.dart';
import '../core/constants/app_constants.dart';
import '../logging/app_logger.dart';

class HistoryService {
  static HistoryService? _instance;
  late Box<String> _box;

  HistoryService._();

  factory HistoryService() {
    _instance ??= HistoryService._();
    return _instance!;
  }

  Future<void> init() async {
    _box = await _openSafeBox(AppConstants.hiveBoxHistory);
  }

  Future<Box<String>> _openSafeBox(String boxName) async {
    try {
      return await Hive.openBox<String>(boxName);
    } catch (e, st) {
      appLogger.e('Failed to open Hive box $boxName, attempting to delete and recreate', error: e, stackTrace: st);
      try {
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox<String>(boxName);
      } catch (re, rest) {
        appLogger.e('Failed to delete/recreate box $boxName', error: re, stackTrace: rest);
        rethrow;
      }
    }
  }

  Future<List<HistoryItem>> loadAll() async {
    final json = _box.get('all_items');
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((item) => HistoryItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<HistoryItem> items) async {
    final list = items.map((item) => item.toMap()).toList();
    await _box.put('all_items', jsonEncode(list));
  }

  Future<void> addItem(HistoryItem item) async {
    final items = await loadAll();
    items.removeWhere((i) => i.id == item.id);
    items.insert(0, item);
    if (items.length > 200) items.removeLast();
    await saveAll(items);
  }

  Future<void> removeItem(String id) async {
    final items = await loadAll();
    items.removeWhere((i) => i.id == id);
    await saveAll(items);
  }

  Future<void> clearAll() async {
    await _box.put('all_items', jsonEncode([]));
  }

  Future<void> clearMagnetLinks() async {
    final items = await loadAll();
    items.removeWhere((i) => i.type == HistoryItemType.magnetLink);
    await saveAll(items);
  }

  Future<void> clearDownloads() async {
    final items = await loadAll();
    items.removeWhere((i) => i.type == HistoryItemType.download);
    await saveAll(items);
  }
}
