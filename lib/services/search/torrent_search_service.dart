import 'dart:async';
import '../../models/torrent.dart';
import '../../logging/app_logger.dart';
import 'providers/piratebay_provider.dart';
import 'providers/eztv_provider.dart';
import 'providers/nyaasi_provider.dart';
import 'providers/yts_provider.dart';
import 'providers/x1337_provider.dart';

enum TorrentSource {
  pirateBay,
  eztv,
  nyaaSi,
  yts,
  x1337,
}

class TorrentSearchService {
  final PirateBayProvider _pirateBay;
  final EZTVProvider _eztv;
  final NyaaSiProvider _nyaaSi;
  final YTSProvider _yts;
  final X1337Provider _x1337;

  TorrentSearchService()
      : _pirateBay = PirateBayProvider(),
        _eztv = EZTVProvider(),
        _nyaaSi = NyaaSiProvider(),
        _yts = YTSProvider(),
        _x1337 = X1337Provider();

  Future<List<TorrentInfo>> searchAll(String query) async {
    final results = await Future.wait([
      _pirateBay.search(query),
      _eztv.search(query),
      _nyaaSi.search(query),
      _yts.search(query),
      _x1337.search(query),
    ], eagerError: false);

    final all = <TorrentInfo>[];
    final seenHashes = <String>{};

    for (final list in results) {
      for (final torrent in list) {
        final key = torrent.infoHash ?? torrent.magnetUri ?? torrent.title;
        if (!seenHashes.contains(key)) {
          seenHashes.add(key);
          all.add(torrent);
        }
      }
    }

    all.sort((a, b) => b.seeders.compareTo(a.seeders));
    appLogger.i('Search found ${all.length} unique results');
    return all;
  }

  Future<List<TorrentInfo>> searchWithFilters(String query, {
    String? category,
    String? source,
    String? minQuality,
    int? minSeeders,
  }) async {
    var results = await searchAll(query);

    if (category != null && category != 'All') {
      results = results.where((t) => _matchesCategory(t, category)).toList();
    }

    if (source != null && source != 'All') {
      results = results.where((t) => t.source == source).toList();
    }

    if (minQuality != null) {
      results = results.where((t) => _qualityRank(t.quality) >= _qualityRank(minQuality)).toList();
    }

    if (minSeeders != null && minSeeders > 0) {
      results = results.where((t) => t.seeders >= minSeeders).toList();
    }

    return results;
  }

  bool _matchesCategory(TorrentInfo torrent, String category) {
    switch (category.toLowerCase()) {
      case 'movies':
      case 'video':
        return torrent.isVideo;
      case 'tv':
      case 'tv shows':
        return torrent.isVideo && (torrent.title.contains(RegExp(r'S\d{2}E\d{2}', caseSensitive: false)) ||
            torrent.title.contains(RegExp(r'Season \d', caseSensitive: false)));
      case 'music':
      case 'audio':
        return torrent.isAudio;
      case 'games':
        return torrent.isGame;
      case 'apps':
      case 'software':
        return torrent.isApp;
      default:
        return true;
    }
  }

  int _qualityRank(String? quality) {
    if (quality == null) return 0;
    switch (quality.toLowerCase()) {
      case '2160p': case '4k': case 'uhd': return 5;
      case '1080p': return 4;
      case '720p': case 'hd': return 3;
      case '480p': return 2;
      case 'sd': return 1;
      default: return 0;
    }
  }

  Future<List<TorrentInfo>> getTopTorrents() => _pirateBay.topTorrents();

  Future<List<TorrentInfo>> searchFromSource(String query, TorrentSource source) async {
    switch (source) {
      case TorrentSource.pirateBay:
        return _pirateBay.search(query);
      case TorrentSource.eztv:
        return _eztv.search(query);
      case TorrentSource.nyaaSi:
        return _nyaaSi.search(query);
      case TorrentSource.yts:
        return _yts.search(query);
      case TorrentSource.x1337:
        return _x1337.search(query);
    }
  }
}
