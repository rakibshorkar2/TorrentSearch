import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;
import '../../../models/torrent.dart';
import '../../../logging/app_logger.dart';

class EZTVProvider {
  final Dio _dio;

  EZTVProvider()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://eztv.re',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'User-Agent': 'TorrentFlow/1.0'},
        ));

  String get name => 'EZTV';

  Future<List<TorrentInfo>> search(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final response = await _dio.get('/search/$encoded');
      return _parseHtml(response.data);
    } catch (e) {
      appLogger.w('EZTV search failed', error: e);
      return [];
    }
  }

  List<TorrentInfo> _parseHtml(String htmlContent) {
    final document = html.parse(htmlContent);
    final rows = document.querySelectorAll('tr.forum_header_border');
    final results = <TorrentInfo>[];

    for (final row in rows) {
      try {
        final nameEl = row.querySelector('a.epinfo');
        if (nameEl == null) continue;
        final title = nameEl.text.trim();

        final magnetEl = row.querySelector('a.magnet');
        final magnetUri = magnetEl?.attributes['href'];

        final sizeEl = row.querySelector('td');
        final sizeText = sizeEl?.text.trim() ?? '0';

        final seedEl = row.querySelectorAll('td').length > 6
            ? row.querySelectorAll('td')[6]
            : null;
        final seeders = int.tryParse(seedEl?.text.trim() ?? '0') ?? 0;

        final leechEl = row.querySelectorAll('td').length > 7
            ? row.querySelectorAll('td')[7]
            : null;
        final leechers = int.tryParse(leechEl?.text.trim() ?? '0') ?? 0;

        final size = _parseSize(sizeText);

        results.add(TorrentInfo(
          id: magnetUri?.hashCode.toString() ?? title.hashCode.toString(),
          title: title,
          magnetUri: magnetUri,
          size: size,
          seeders: seeders,
          leechers: leechers,
          uploadDate: DateTime.now(),
          source: name,
          isVideo: true,
          quality: TorrentInfo.parseQuality(title),
        ));
      } catch (_) {}
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
