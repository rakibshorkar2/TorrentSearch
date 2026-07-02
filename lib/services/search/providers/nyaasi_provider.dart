import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;
import '../../../models/torrent.dart';
import '../../../logging/app_logger.dart';

class NyaaSiProvider {
  final Dio _dio;

  NyaaSiProvider()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://nyaa.si',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'User-Agent': 'TorrentFlow/1.0'},
        ));

  String get name => 'Nyaa.si';

  Future<List<TorrentInfo>> search(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final response = await _dio.get('/?f=0&c=0_0&q=$encoded&s=seeders&o=desc');
      return _parseHtml(response.data);
    } catch (e) {
      appLogger.w('Nyaa.si search failed', error: e);
      return [];
    }
  }

  List<TorrentInfo> _parseHtml(String htmlContent) {
    final document = html.parse(htmlContent);
    final rows = document.querySelectorAll('table.torrent-list > tbody > tr');
    final results = <TorrentInfo>[];

    for (final row in rows) {
      try {
        final links = row.querySelectorAll('a');
        if (links.length < 2) continue;

        final title = links[1].text.trim();
        final magnetEl = row.querySelector('a[href*="magnet:"]');
        final magnetUri = magnetEl?.attributes['href'];

        final tds = row.querySelectorAll('td');
        if (tds.length < 6) continue;

        final sizeText = tds[3].text.trim();
        final seeders = int.tryParse(tds[5].text.trim()) ?? 0;
        final leechers = int.tryParse(tds[6].text.trim()) ?? 0;

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
          quality: TorrentInfo.parseQuality(title),
        ));
      } catch (_) {}
    }

    return results;
  }

  int _parseSize(String size) {
    final parts = size.trim().split(' ');
    if (parts.length != 2) return 0;
    final num = double.tryParse(parts[0]) ?? 0;
    final unit = parts[1].toLowerCase();
    if (unit.contains('gib') || unit.contains('gb')) return (num * 1024 * 1024 * 1024).toInt();
    if (unit.contains('mib') || unit.contains('mb')) return (num * 1024 * 1024).toInt();
    if (unit.contains('kib') || unit.contains('kb')) return (num * 1024).toInt();
    return 0;
  }
}
