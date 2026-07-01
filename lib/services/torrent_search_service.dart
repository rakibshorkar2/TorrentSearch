import 'package:dio/dio.dart';
import '../models/torrent.dart';

class TorrentSearchService {
  final Dio _dio;

  TorrentSearchService()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://apibay.org',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'User-Agent': 'TorrentFlow/1.0'},
        ));

  Future<List<TorrentInfo>> search(String query) async {
    final encoded = Uri.encodeComponent(query);
    final response = await _dio.get('/q.php?q=$encoded&cat=0');
    return _parseResponse(response.data);
  }

  Future<List<TorrentInfo>> getTopTorrents() async {
    final response = await _dio.get('/precompiled/data_top100_201.json');
    return _parseResponse(response.data);
  }

  List<TorrentInfo> _parseResponse(dynamic data) {
    if (data is! List) return [];
    return data
        .map((item) {
          if (item is! Map) return null;
          try {
            return TorrentInfo.fromJson(Map<String, dynamic>.from(item));
          } catch (_) {
            return null;
          }
        })
        .whereType<TorrentInfo>()
        .toList();
  }
}
