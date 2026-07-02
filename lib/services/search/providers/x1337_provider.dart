import 'package:dio/dio.dart';
import '../../../../logging/app_logger.dart';
import '../../../models/torrent.dart';

class X1337Provider {
  final Dio _dio;

  X1337Provider()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://1337x.to',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            'User-Agent': 'TorrentFlow/1.0',
            'Accept': 'text/html,application/xhtml+xml',
          },
        ));

  String get name => '1337x';

  Future<List<TorrentInfo>> search(String query, {String? category}) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final cat = _categoryPath(category);
      final response = await _dio.get('/category-search/$encoded/$cat/1/');
      return _parseHtml(response.data);
    } catch (e) {
      appLogger.w('1337x search failed', error: e);
      return [];
    }
  }

  String _categoryPath(String? category) {
    switch (category) {
      case 'Movies': return 'movies';
      case 'TV': return 'tv';
      case 'Games': return 'games';
      case 'Music': return 'music';
      case 'Apps': return 'apps';
      default: return 'all';
    }
  }

  List<TorrentInfo> _parseHtml(String htmlContent) {
    final results = <TorrentInfo>[];
    final namePattern = RegExp(r'<a href="/torrent/\d+/[^"]+">([^<]+)</a>');
    final seedPattern = RegExp(r'<td class="seeds">(\d+)</td>');
    const leechPattern = r'<td class="leeches">(\d+)</td>';
    const sizePattern = r'<td class="size">([^<]+)</td>';

    final names = namePattern.allMatches(htmlContent).map((m) => m.group(1)?.trim() ?? '').toList();
    final seeds = seedPattern.allMatches(htmlContent).map((m) => int.tryParse(m.group(1) ?? '0') ?? 0).toList();
    final leeches = RegExp(leechPattern).allMatches(htmlContent).map((m) => int.tryParse(m.group(1) ?? '0') ?? 0).toList();
    final sizes = RegExp(sizePattern).allMatches(htmlContent).map((m) => m.group(1)?.trim() ?? '0').toList();

    for (var i = 0; i < names.length && i < seeds.length; i++) {
      try {
        final size = _parseSize(sizes.length > i ? sizes[i] : '0');
        results.add(TorrentInfo(
          id: names[i].hashCode.toString(),
          title: names[i],
          size: size,
          seeders: seeds.length > i ? seeds[i] : 0,
          leechers: leeches.length > i ? leeches[i] : 0,
          uploadDate: DateTime.now(),
          source: name,
          quality: TorrentInfo.parseQuality(names[i]),
        ));
      } catch (_) {}
    }

    return results;
  }

  int _parseSize(String size) {
    final lower = size.toLowerCase().replaceAll('&nbsp;', ' ').trim();
    if (lower.contains('gb')) {
      final num = double.tryParse(lower.replaceAll('gb', '').trim()) ?? 0;
      return (num * 1024 * 1024 * 1024).toInt();
    }
    if (lower.contains('mb')) {
      final num = double.tryParse(lower.replaceAll('mb', '').trim()) ?? 0;
      return (num * 1024 * 1024).toInt();
    }
    if (lower.contains('kb')) {
      final num = double.tryParse(lower.replaceAll('kb', '').trim()) ?? 0;
      return (num * 1024).toInt();
    }
    return 0;
  }
}
