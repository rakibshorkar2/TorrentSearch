import 'package:dio/dio.dart';
import '../../../models/torrent.dart';
import '../../../logging/app_logger.dart';

class PirateBayProvider {
  final Dio _dio;

  PirateBayProvider()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://apibay.org',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'User-Agent': 'TorrentFlow/1.0'},
        ));

  String get name => 'The Pirate Bay';

  Future<List<TorrentInfo>> search(String query, {String? category}) async {
    final encoded = Uri.encodeComponent(query);
    final cat = category ?? '0';
    try {
      final response = await _dio.get('/q.php?q=$encoded&cat=$cat');
      return _parseResponse(response.data, source: name);
    } catch (e) {
      appLogger.w('PirateBay search failed', error: e);
      return [];
    }
  }

  Future<List<TorrentInfo>> topTorrents() async {
    try {
      final response = await _dio.get('/precompiled/data_top100_201.json');
      return _parseResponse(response.data, source: name);
    } catch (e) {
      appLogger.w('PirateBay top torrents failed', error: e);
      return [];
    }
  }

  List<TorrentInfo> _parseResponse(dynamic data, {String? source}) {
    if (data is! List) return [];
    return data
        .map((item) {
          if (item is! Map) return null;
          try {
            final info = TorrentInfo.fromJson(Map<String, dynamic>.from(item));
            return TorrentInfo(
              id: info.id,
              title: info.title,
              magnetUri: info.magnetUri,
              infoHash: info.infoHash,
              size: info.size,
              seeders: info.seeders,
              leechers: info.leechers,
              uploadDate: info.uploadDate,
              category: info.category,
              fileUrl: info.fileUrl,
              source: source,
              quality: info.quality,
              isVideo: info.isVideo,
              isAudio: info.isAudio,
              isGame: info.isGame,
              isApp: info.isApp,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<TorrentInfo>()
        .toList();
  }
}
