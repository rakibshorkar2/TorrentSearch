import 'package:dio/dio.dart';
import '../../../models/torrent.dart';
import '../../../logging/app_logger.dart';

class YTSProvider {
  final Dio _dio;

  YTSProvider()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://yts.mx/api/v2',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'User-Agent': 'TorrentFlow/1.0'},
        ));

  String get name => 'YTS';

  Future<List<TorrentInfo>> search(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final response = await _dio.get('/list_movies.json?query_term=$encoded&sort=seeds&order_by=desc&limit=50');
      return _parseResponse(response.data);
    } catch (e) {
      appLogger.w('YTS search failed', error: e);
      return [];
    }
  }

  List<TorrentInfo> _parseResponse(dynamic data) {
    final results = <TorrentInfo>[];
    try {
      final movies = data['data']?['movies'] as List? ?? [];
      for (final movie in movies) {
        final title = movie['title'] ?? 'Unknown';
        final year = movie['year']?.toString() ?? '';
        final fullTitle = '$title ($year)';
        final torrents = movie['torrents'] as List? ?? [];

        for (final torrent in torrents) {
          final quality = torrent['quality'] ?? 'Unknown';
          final size = torrent['size'] ?? '0';
          final seeds = int.tryParse(torrent['seeds']?.toString() ?? '0') ?? 0;
          final peers = int.tryParse(torrent['peers']?.toString() ?? '0') ?? 0;
          final hash = torrent['hash']?.toString() ?? '';

          final magnetUri = 'magnet:?xt=urn:btih:$hash&dn=${Uri.encodeComponent(fullTitle)}';

          results.add(TorrentInfo(
            id: hash,
            title: '$fullTitle [$quality]',
            magnetUri: magnetUri,
            infoHash: hash,
            size: _parseSize(size),
            seeders: seeds,
            leechers: peers,
            uploadDate: DateTime.now(),
            source: name,
            quality: quality,
            isVideo: true,
          ));
        }
      }
    } catch (e) {
      appLogger.w('YTS parse error', error: e);
    }
    return results;
  }

  int _parseSize(String size) {
    final lower = size.toLowerCase();
    if (lower.contains('gb')) {
      final num = double.tryParse(lower.replaceAll('gb', '').trim()) ?? 0;
      return (num * 1024 * 1024 * 1024).toInt();
    }
    if (lower.contains('mb')) {
      final num = double.tryParse(lower.replaceAll('mb', '').trim()) ?? 0;
      return (num * 1024 * 1024).toInt();
    }
    return 0;
  }
}
