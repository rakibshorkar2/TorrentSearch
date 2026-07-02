import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../logging/app_logger.dart';

class PeerInfo {
  final String ip;
  final int port;

  PeerInfo({required this.ip, required this.port});
}

class TrackerResponse {
  final int interval;
  final List<PeerInfo> peers;

  TrackerResponse({required this.interval, required this.peers});
}

class TrackerClient {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<TrackerResponse?> announce({
    required String trackerUrl,
    required String infoHashHex,
    required int fileSize,
    int uploaded = 0,
    int downloaded = 0,
    int port = 6881,
  }) async {
    try {
      final url = '${trackerUrl.replaceAll('announce', 'announce')}'
          '?info_hash=${Uri.encodeComponent(infoHashHex)}'
          '&peer_id=${Uri.encodeComponent('-TF0001-${_randomId()}')}'
          '&port=$port'
          '&uploaded=$uploaded'
          '&downloaded=$downloaded'
          '&left=${fileSize - downloaded}'
          '&compact=1'
          '&event=started';

      final response = await _dio.get(url,
        options: Options(responseType: ResponseType.bytes),
      );

      return _parseResponse(response.data as Uint8List);
    } catch (e) {
      appLogger.w('Tracker announce failed for $trackerUrl', error: e);
      return null;
    }
  }

  TrackerResponse _parseResponse(Uint8List data) {
    final text = utf8.decode(data);
    if (!text.startsWith('d')) return TrackerResponse(interval: 1800, peers: []);

    final map = _parseBencodedMap(text);
    final interval = map['interval'] is int ? map['interval'] as int : 1800;
    final peersRaw = map['peers'];
    final peers = <PeerInfo>[];

    if (peersRaw is String && peersRaw.isNotEmpty) {
      final bytes = peersRaw.codeUnits;
      for (var i = 0; i + 6 <= bytes.length; i += 6) {
        peers.add(PeerInfo(
          ip: '${bytes[i]}.${bytes[i + 1]}.${bytes[i + 2]}.${bytes[i + 3]}',
          port: (bytes[i + 4] << 8) | bytes[i + 5],
        ));
      }
    }

    return TrackerResponse(interval: interval, peers: peers);
  }

  Map<String, dynamic> _parseBencodedMap(String data) {
    final result = <String, dynamic>{};
    if (!data.startsWith('d')) return result;
    var pos = 1;
    while (pos < data.length && data[pos] != 'e') {
      final colon = data.indexOf(':', pos);
      final keyLen = int.parse(data.substring(pos, colon));
      final key = data.substring(colon + 1, colon + 1 + keyLen);
      pos = colon + 1 + keyLen;

      if (data[pos] == 'i') {
        final end = data.indexOf('e', pos);
        result[key] = int.parse(data.substring(pos + 1, end));
        pos = end + 1;
      } else if (data[pos] == 'l' || data[pos] == 'd') {
        final end = _findEnd(data, pos);
        result[key] = data.substring(pos, end + 1);
        pos = end + 1;
      } else {
        final colon2 = data.indexOf(':', pos);
        final len = int.parse(data.substring(pos, colon2));
        result[key] = data.substring(colon2 + 1, colon2 + 1 + len);
        pos = colon2 + 1 + len;
      }
    }
    return result;
  }

  int _findEnd(String data, int start) {
    var depth = 0;
    for (var i = start; i < data.length; i++) {
      if (data[i] == 'd' || data[i] == 'l') depth++;
      if (data[i] == 'e') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return data.length - 1;
  }

  String _randomId() {
    final sb = StringBuffer();
    for (var i = 0; i < 12; i++) {
      sb.write((DateTime.now().microsecondsSinceEpoch % 10).toString());
    }
    return sb.toString().substring(0, 12);
  }
}
