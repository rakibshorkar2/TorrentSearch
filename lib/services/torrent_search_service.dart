import 'package:dio/dio.dart';
import '../models/torrent.dart';
import '../core/constants/app_constants.dart';

class TorrentSearchService {
  final Dio _dio;

  TorrentSearchService() : _dio = Dio(BaseOptions(
    baseUrl: AppConstants.defaultTorrentSearchUrl,
    connectTimeout: AppConstants.connectionTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    headers: {'User-Agent': 'TorrentFlow/1.0'},
  ));

  Future<List<TorrentInfo>> search(String query, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '/q.php',
        queryParameters: {
          'q': query,
          'page': page,
          'cat': 0,
        },
      );
      return _parseResponse(response.data);
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionTimeout) {
        throw TorrentSearchException('Connection timed out. Please check your network.');
      }
      throw TorrentSearchException('Search failed: ${e.toString()}');
    }
  }

  Future<List<TorrentInfo>> getTopTorrents() async {
    try {
      final response = await _dio.get('/precompiled/data_top100.json');
      return _parseResponse(response.data);
    } catch (e) {
      throw TorrentSearchException('Failed to fetch top torrents: ${e.toString()}');
    }
  }

  List<TorrentInfo> _parseResponse(dynamic data) {
    if (data == null) return [];
    final list = data as List;
    return list.map((item) {
      return TorrentInfo(
        id: item['id']?.toString() ?? '',
        title: item['name'] ?? 'Unknown',
        infoHash: item['info_hash'],
        magnetUri: _buildMagnetUri(item),
        size: int.tryParse(item['size']?.toString() ?? '0') ?? 0,
        seeders: int.tryParse(item['seeders']?.toString() ?? '0') ?? 0,
        leechers: int.tryParse(item['leechers']?.toString() ?? '0') ?? 0,
        uploadDate: _parseDate(item['added']?.toString()),
        category: item['category']?.toString(),
      );
    }).toList();
  }

  String? _buildMagnetUri(dynamic item) {
    final hash = item['info_hash']?.toString();
    if (hash == null || hash.isEmpty) return null;
    final name = Uri.encodeComponent(item['name']?.toString() ?? '');
    return 'magnet:?xt=urn:btih:$hash&dn=$name&tr=udp://tracker.opentrackr.org:1337&tr=udp://tracker.coppersurfer.tk:6969&tr=udp://tracker.leechers-paradise.org:6969&tr=udp://open.demonii.com:1337';
  }

  DateTime _parseDate(String? timestamp) {
    if (timestamp == null) return DateTime.now();
    final seconds = int.tryParse(timestamp);
    if (seconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return DateTime.now();
  }
}

class TorrentSearchException implements Exception {
  final String message;
  TorrentSearchException(this.message);

  @override
  String toString() => message;
}
