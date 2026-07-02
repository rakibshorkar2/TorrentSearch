import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';

class PeerInfo {
  final String ip;
  final int port;
  PeerInfo(this.ip, this.port);
}

class TrackerResponse {
  final int interval;
  final int leechers;
  final int seeders;
  final List<PeerInfo> peers;

  TrackerResponse({
    required this.interval,
    required this.leechers,
    required this.seeders,
    required this.peers,
  });
}

class TrackerClient {
  static final Random _random = Random();
  int _transactionId = 0;

  Future<TrackerResponse?> announce({
    required String trackerUrl,
    required String infoHashHex,
    required int fileSize,
  }) async {
    final uri = Uri.tryParse(trackerUrl);
    if (uri == null) return null;

    if (uri.scheme == 'udp') {
      return _announceUdp(uri, infoHashHex, fileSize);
    }
    return null;
  }

  Future<TrackerResponse?> _announceUdp(
    Uri uri,
    String infoHashHex,
    int fileSize,
  ) async {
    final host = uri.host;
    final port = uri.port;

    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final remoteAddr = InternetAddress.tryParse(host) ?? (await InternetAddress.lookup(host)).first;
      final remotePort = port > 0 ? port : 80;

      _transactionId = _random.nextInt(1 << 30);

      final connectReq = _buildConnectRequest();
      socket.send(connectReq, remoteAddr, remotePort);

      final connectResp = await _readResponse(socket, 16, const Duration(seconds: 15));
      if (connectResp == null) return null;

      final connectionId = ByteData.view(connectResp.buffer, 8, 8).getUint64(0);
      final infoHash = _hexToBytes(infoHashHex);

      _transactionId = _random.nextInt(1 << 30);
      final peerId = _generatePeerId();

      final announceReq = _buildAnnounceRequest(connectionId, infoHash, peerId, fileSize);
      socket.send(announceReq, remoteAddr, remotePort);

      final announceResp = await _readResponse(socket, 20, const Duration(seconds: 30));
      if (announceResp == null || announceResp.length < 20) return null;

      final view = ByteData.view(announceResp.buffer);
      final action = view.getUint32(0);
      if (action != 1) return null;

      final interval = view.getUint32(8);
      final leechers = view.getUint32(12);
      final seeders = view.getUint32(16);

      final peers = <PeerInfo>[];
      for (var i = 20; i + 6 <= announceResp.length; i += 6) {
        final ipBytes = announceResp.sublist(i, i + 4);
        final ip = '${ipBytes[0]}.${ipBytes[1]}.${ipBytes[2]}.${ipBytes[3]}';
        final p = ByteData.view(announceResp.buffer, i + 4, 2).getUint16(0);
        if (ip != '0.0.0.0' && p > 0) {
          peers.add(PeerInfo(ip, p));
        }
      }

      return TrackerResponse(
        interval: interval,
        leechers: leechers,
        seeders: seeders,
        peers: peers,
      );
    } catch (e) {
      return null;
    } finally {
      socket?.close();
    }
  }

  Uint8List _buildConnectRequest() {
    final data = ByteData(16);
    data.setUint64(0, 0x41727101980, Endian.big);
    data.setUint32(8, 0, Endian.big);
    data.setUint32(12, _transactionId, Endian.big);
    return data.buffer.asUint8List();
  }

  Uint8List _buildAnnounceRequest(
    int connectionId,
    Uint8List infoHash,
    Uint8List peerId,
    int fileSize,
  ) {
    final data = ByteData(98);
    data.setUint64(0, connectionId, Endian.big);
    data.setUint32(8, 1, Endian.big);
    data.setUint32(12, _transactionId, Endian.big);
    for (var i = 0; i < 20; i++) { data.setUint8(16 + i, infoHash[i]); }
    for (var i = 0; i < 20; i++) { data.setUint8(36 + i, peerId[i]); }
    data.setUint64(56, 0, Endian.big);
    data.setUint64(64, fileSize, Endian.big);
    data.setUint64(72, 0, Endian.big);
    data.setUint32(80, 2, Endian.big);
    data.setUint32(84, 0, Endian.big);
    data.setUint32(88, _random.nextInt(1 << 30), Endian.big);
    data.setUint32(92, -1, Endian.big);
    data.setUint16(96, 6881, Endian.big);
    return data.buffer.asUint8List();
  }

  Future<Uint8List?> _readResponse(RawDatagramSocket socket, int minLen, Duration timeout) async {
    final completer = Completer<Uint8List?>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(null);
    });

    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();
        if (datagram != null) {
          final data = Uint8List.fromList(datagram.data);
          if (data.length >= minLen) {
            if (!completer.isCompleted) completer.complete(data);
          }
        }
      }
    });

    final result = await completer.future;
    timer.cancel();
    return result;
  }

  Uint8List _generatePeerId() {
    final id = Uint8List(20);
    id[0] = 84; id[1] = 70; id[2] = 45; id[3] = 84; id[4] = 70;
    for (var i = 5; i < 20; i++) { id[i] = _random.nextInt(256); }
    return id;
  }

  Uint8List _hexToBytes(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }
}
