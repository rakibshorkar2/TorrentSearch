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
      return await _parseHtml(response.data);
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

  Future<List<TorrentInfo>> _parseHtml(String htmlContent) async {
    final results = <TorrentInfo>[];
    final torrentPattern = RegExp(r'<a href="/torrent/([^"]+)">([^<]+)</a>');
    final seedPattern = RegExp(r'<td class="seeds">(\d+)</td>');
    const leechPattern = r'<td class="leeches">(\d+)</td>';
    const sizePattern = r'<td class="size">([^<]+)</td>';

    final torrentMatches = torrentPattern.allMatches(htmlContent).toList();
    final seeds = seedPattern.allMatches(htmlContent).map((m) => int.tryParse(m.group(1) ?? '0') ?? 0).toList();
    final leeches = RegExp(leechPattern).allMatches(htmlContent).map((m) => int.tryParse(m.group(1) ?? '0') ?? 0).toList();
    final sizes = RegExp(sizePattern).allMatches(htmlContent).map((m) => m.group(1)?.trim() ?? '0').toList();

    final names = <String>[];
    final detailPaths = <String>[];
    for (var i = 0; i < torrentMatches.length; i++) {
      final path = torrentMatches[i].group(1) ?? '';
      final name = torrentMatches[i].group(2)?.trim() ?? '';
      if (name.isNotEmpty) {
        names.add(name);
        detailPaths.add('/torrent/$path');
      }
    }

    final magnetUris = await _fetchMagnetLinks(detailPaths);

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
          magnetUri: magnetUris.length > i ? magnetUris[i] : null,
        ));
      } catch (_) {}
    }

    return results;
  }

  Future<List<String?>> _fetchMagnetLinks(List<String> paths) async {
    if (paths.isEmpty) return [];
    final results = List<String?>.filled(paths.length, null);
    const batchSize = 5;
    for (var start = 0; start < paths.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, paths.length);
      final batch = paths.sublist(start, end);
      final futures = batch.map((path) => _fetchMagnetLink(path));
      final batchResults = await Future.wait(futures, eagerError: false);
      for (var i = 0; i < batchResults.length; i++) {
        results[start + i] = batchResults[i];
      }
    }
    return results;
  }

  Future<String?> _fetchMagnetLink(String path) async {
    try {
      final response = await _dio.get(path, options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final magnetPattern = RegExp(r'href="(magnet:\?xt=urn:btih:[^"]+)"');
      final match = magnetPattern.firstMatch(response.data);
      return match?.group(1);
    } catch (e) {
      return null;
    }
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
