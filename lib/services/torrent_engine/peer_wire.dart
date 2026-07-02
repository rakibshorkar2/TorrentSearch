import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class PeerWireMessage {
  static const int choke = 0;
  static const int unchoke = 1;
  static const int interested = 2;
  static const int notInterested = 3;
  static const int have = 4;
  static const int bitfield = 5;
  static const int request = 6;
  static const int piece = 7;
  static const int cancel = 8;
  static const int port = 9;
  static const int extended = 20;
}

class PeerConnection {
  Socket? _socket;
  bool _connected = false;
  bool _peerChoking = true;
  int _utMetadataId = 0;
  int _metadataSize = 0;
  Uint8List? _metadata;
  final Map<int, Uint8List> _metadataPieces = {};
  final Completer<void> _metadataDone = Completer();
  StreamController<Uint8List>? _pieceController;
  StreamSubscription<Uint8List>? _socketSubscription;
  int _bufferOffset = 0;
  Uint8List _buffer = Uint8List(0);
  final Random _random = Random();

  bool get isConnected => _connected;

  Future<bool> connect(String ip, int port, String infoHashHex, int timeoutSec) async {
    try {
      _socket = await Socket.connect(ip, port,
        timeout: Duration(seconds: timeoutSec),
      );
      final handshake = _buildHandshake(infoHashHex);
      _socket!.add(handshake);
      final response = await _socket!.first;
      if (response.length < 68) {
        _socket!.close();
        return false;
      }
      _connected = true;
      return true;
    } catch (_) {
      _connected = false;
      return false;
    }
  }

  Uint8List _buildHandshake(String infoHashHex) {
    final infoHash = _hexToBytes(infoHashHex);
    final peerId = utf8.encode('-TF0001-${_randomString(12)}');
    final buf = BytesBuilder();
    buf.addByte(19);
    buf.add(utf8.encode('BitTorrent protocol'));
    buf.add(Uint8List(8));
    buf.add(infoHash);
    buf.add(peerId);
    return buf.toBytes();
  }

  void sendUnchoke() {
    _sendMessage(PeerWireMessage.unchoke);
  }

  void sendInterested() {
    _sendMessage(PeerWireMessage.interested);
  }

  void requestPiece(int index, int begin, int length) {
    if (!_peerChoking && _socket != null) {
      _sendRequestMessage(index, begin, length);
    }
  }

  void _sendRequestMessage(int index, int begin, int length) {
    final payload = Uint8List(12);
    final bd = ByteData.view(payload.buffer);
    bd.setUint32(0, index, Endian.big);
    bd.setUint32(4, begin, Endian.big);
    bd.setUint32(8, length, Endian.big);
    _sendMessage(PeerWireMessage.request, payload);
  }

  void startMessageLoop(StreamController<Uint8List> pieceController) {
    _pieceController = pieceController;
    if (_socketSubscription == null && _socket != null) {
      _socketSubscription = _socket!.listen(
        (data) => _handleData(data),
        onError: (_) => _cleanup(),
        onDone: () => _cleanup(),
      );
    }
  }

  void _handleData(Uint8List data) {
    if (_buffer.length < _bufferOffset + data.length) {
      final newBuf = Uint8List(_bufferOffset + data.length);
      newBuf.setRange(0, _bufferOffset, _buffer);
      _buffer = newBuf;
    }
    _buffer.setRange(_bufferOffset, _bufferOffset + data.length, data);
    _bufferOffset += data.length;

    while (_bufferOffset >= 4) {
      final len = ByteData.view(_buffer.buffer, 0, 4).getUint32(0, Endian.big);
      if (len == 0) {
        _buffer = _buffer.sublist(4);
        _bufferOffset -= 4;
        continue;
      }
      if (_bufferOffset < 4 + len) break;
      final msg = _buffer.sublist(4, 4 + len);
      _processMessage(msg);
      _buffer = _buffer.sublist(4 + len);
      _bufferOffset -= 4 + len;
    }
  }

  void _processMessage(Uint8List msg) {
    if (msg.isEmpty) return;
    final id = msg[0];
    final payload = msg.length > 1 ? msg.sublist(1) : null;

    switch (id) {
      case PeerWireMessage.choke:
        _peerChoking = true;
      case PeerWireMessage.unchoke:
        _peerChoking = false;
      case PeerWireMessage.piece:
        _handlePiece(payload);
      case PeerWireMessage.extended:
        _handleExtended(payload);
    }
  }

  void _handlePiece(Uint8List? payload) {
    if (payload == null || payload.length < 8) return;
    final block = payload.sublist(8);
    if (_pieceController != null && !_pieceController!.isClosed) {
      _pieceController!.add(block);
    }
  }

  void _handleExtended(Uint8List? payload) {
    if (payload == null || payload.isEmpty) return;
    final extPayload = payload.sublist(1);
    final extId = payload[0];

    if (extId == 0) {
      _handleExtHandshake(extPayload);
    } else if (extId == _utMetadataId) {
      _handleMetadataMessage(extPayload);
    }
  }

  void _handleExtHandshake(Uint8List payload) {
    try {
      final map = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
      final m = map['m'] as Map<String, dynamic>?;
      if (m != null) {
        _utMetadataId = (m['ut_metadata'] as int?) ?? 0;
        _metadataSize = (map['metadata_size'] as int?) ?? 0;
      }
      if (_utMetadataId > 0 && _metadataSize > 0) {
        _requestMetadataPieces();
      }
    } catch (_) {}
  }

  void _requestMetadataPieces() {
    final numPieces = (_metadataSize + 16383) ~/ 16384;
    for (var i = 0; i < numPieces; i++) {
      final req = jsonEncode({'msg_type': 0, 'piece': i});
      final extPayload = Uint8List.fromList(utf8.encode(req));
      final msg = Uint8List(2 + extPayload.length);
      msg[0] = _utMetadataId;
      msg.setRange(1, extPayload.length + 1, extPayload);
      _sendMessage(PeerWireMessage.extended, msg);
    }
  }

  void _handleMetadataMessage(Uint8List payload) {
    try {
      int dictEnd = -1;
      for (int i = 0; i < payload.length - 1; i++) {
        if (payload[i] == 0x65 && payload[i + 1] == 0x65) {
          dictEnd = i;
          break;
        }
      }
      if (dictEnd < 0) return;
      final dictStr = utf8.decode(payload.sublist(0, dictEnd + 2));
      final map = jsonDecode(dictStr) as Map<String, dynamic>;
      final piece = map['piece'] as int?;
      final totalSize = map['total_size'] as int?;
      if (totalSize != null) _metadataSize = totalSize;
      final dataStart = dictEnd + 2;
      if (piece != null && dataStart < payload.length) {
        _metadataPieces[piece] = payload.sublist(dataStart);
      }
      if (totalSize != null && _metadataPieces.isNotEmpty) {
        final total = _metadataPieces.values.fold(0, (int sum, p) => sum + p.length);
        if (total >= totalSize) {
          final sorted = List.generate(_metadataPieces.length, (i) => _metadataPieces[i]!);
          _metadata = Uint8List(totalSize);
          var offset = 0;
          for (final pieceData in sorted) {
            final end = (offset + pieceData.length).clamp(0, totalSize);
            _metadata!.setRange(offset, end, pieceData);
            offset = end;
          }
          if (!_metadataDone.isCompleted) _metadataDone.complete();
        }
      }
    } catch (_) {}
  }

  Future<Uint8List?> fetchMetadata(String infoHashHex) async {
    try {
      await _metadataDone.future.timeout(const Duration(seconds: 30));
      return _metadata;
    } catch (_) {
      return null;
    }
  }

  void _sendMessage(int id, [Uint8List? payload]) {
    if (_socket == null) return;
    final len = 1 + (payload?.length ?? 0);
    final msg = Uint8List(4 + len);
    final bd = ByteData.view(msg.buffer);
    bd.setUint32(0, len, Endian.big);
    msg[4] = id;
    if (payload != null) msg.setRange(5, 5 + payload.length, payload);
    _socket!.add(msg);
  }

  void close() {
    _socketSubscription?.cancel();
    _socket?.close();
    _connected = false;
  }

  void _cleanup() {
    _socketSubscription?.cancel();
    _socketSubscription = null;
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(_random.nextInt(chars.length))),
    );
  }

  Uint8List _hexToBytes(String hex) {
    final result = Uint8List(20);
    for (var i = 0; i < 40; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }
}
