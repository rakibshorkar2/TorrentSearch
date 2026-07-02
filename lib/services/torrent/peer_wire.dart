import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class PeerWireMessage {
  final int id;
  final Uint8List? payload;

  PeerWireMessage(this.id, this.payload);

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
  int _metadataReceived = 0;
  final Map<int, Uint8List> _metadataPieces = {};

  final Completer<void> _metadataDone = Completer();
  StreamController<Uint8List>? _pieceController;

  int _bufferOffset = 0;
  Uint8List _buffer = Uint8List(0);

  final Random _random = Random();

  Future<bool> connect(String ip, int port, String infoHashHex, int timeoutSec) async {
    try {
      _socket = await Socket.connect(ip, port,
        timeout: Duration(seconds: timeoutSec),
      );
      _connected = true;

      final infoHash = _hexToBytes(infoHashHex);
      _socket!.add(_buildHandshake(infoHash));

      final resp = await _readExactly(_socket!, 68, Duration(seconds: 10));
      if (resp == null || resp.length < 68) return false;
      if (resp[0] != 19) return false;
      final protocolStr = utf8.decode(resp.sublist(1, 20));
      if (protocolStr != 'BitTorrent protocol') return false;

      _peerChoking = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Uint8List?> fetchMetadata(String infoHashHex) async {
    if (_socket == null || !_connected) return null;

    _sendMessage(PeerWireMessage.interested, null);
    await _sendExtHandshake();

    await Future.delayed(const Duration(seconds: 2));
    if (_metadataSize > 0) {
      await _requestMetadataPieces();
      try {
        await _metadataDone.future.timeout(const Duration(seconds: 60));
      } catch (_) {}
    }

    return _metadata;
  }

  Future<void> _sendExtHandshake() async {
    final payload = utf8.encode(json.encode({
      'm': {'ut_metadata': 1},
      'v': 'TorrentFlow 1.0',
    }));
    _socket!.add(_buildExtendedMessage(0, payload));
  }

  int _pendingPieceIndex = 0;
  int _pendingBegin = 0;
  int _pendingLength = 16384;

  void requestPiece(int index, int begin, int length) {
    _pendingPieceIndex = index;
    _pendingBegin = begin;
    _pendingLength = length;
    if (!_peerChoking && _socket != null) {
      _sendRequestMessage(index, begin, length);
    }
  }

  void startMessageLoop(StreamController<Uint8List> pieceController) {
    _pieceController = pieceController;
    _socket!.listen(
      (data) => _handleData(data),
      onError: (_) => _cleanup(),
      onDone: () => _cleanup(),
    );
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
        if (_pieceController != null && !_pieceController!.isClosed) {
          _sendRequestMessage(_pendingPieceIndex, _pendingBegin, _pendingLength);
        }
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
    if (_pieceController != null && !_pieceController!.isClosed) {
      _pieceController!.close();
    }
  }

  void _handleExtended(Uint8List? payload) {
    if (payload == null || payload.isEmpty) return;
    final extId = payload[0];
    final extPayload = payload.sublist(1);

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
        _utMetadataId = (m['ut_metadata'] as num?)?.toInt() ?? 0;
      }
      _metadataSize = (map['metadata_size'] as num?)?.toInt() ?? 0;
    } catch (_) {}
  }

  void _handleMetadataMessage(Uint8List payload) {
    try {
      int pos = 0;
      final dict = <String, dynamic>{};
      while (pos < payload.length && payload[pos] != 101) {
        if (payload[pos] < 48 || payload[pos] > 57) { pos++; continue; }
        final colon = _indexOf(payload, 58, pos);
        if (colon < 0) break;
        final len = int.parse(utf8.decode(payload.sublist(pos, colon)));
        final key = utf8.decode(payload.sublist(colon + 1, colon + 1 + len));
        pos = colon + 1 + len;
        if (pos < payload.length && payload[pos] == 105) { // 'i'
          final end = _indexOf(payload, 101, pos);
          if (end < 0) break;
          dict[key] = int.parse(utf8.decode(payload.sublist(pos + 1, end)));
          pos = end + 1;
        }
      }

      final msgType = dict['msg_type'] as int?;
      final piece = dict['piece'] as int?;
      if (msgType == null || piece == null) return;

      if (msgType == 1) {
        final dataStart = _findDataStart(payload);
        if (dataStart < 0) return;
        final pieceData = payload.sublist(dataStart);
        _metadataPieces[piece] = pieceData;
        _metadataReceived += pieceData.length;

        if (_metadataSize > 0 && _metadataReceived >= _metadataSize) {
          final sortedKeys = _metadataPieces.keys.toList()..sort();
          final full = BytesBuilder();
          for (final k in sortedKeys) {
            full.add(_metadataPieces[k]!);
          }
          final all = full.toBytes();
          _metadata = Uint8List.fromList(all.sublist(0, _metadataSize));
          if (!_metadataDone.isCompleted) _metadataDone.complete();
        }
      }
    } catch (_) {}
  }

  int _findDataStart(Uint8List data) {
    for (var i = data.length - 1; i >= 0; i--) {
      if (data[i] == 101 && i < data.length - 1) return i + 1;
    }
    return -1;
  }

  int _indexOf(Uint8List data, int byte, int start) {
    for (var i = start; i < data.length; i++) {
      if (data[i] == byte) return i;
    }
    return -1;
  }

  Uint8List _buildHandshake(Uint8List infoHash) {
    final data = ByteData(68);
    data.setUint8(0, 19);
    final proto = 'BitTorrent protocol';
    for (var i = 0; i < 19; i++) { data.setUint8(1 + i, proto.codeUnitAt(i)); }
    final reserved = Uint8List(8);
    reserved[5] = 0x10;
    for (var i = 0; i < 8; i++) { data.setUint8(20 + i, reserved[i]); }
    for (var i = 0; i < 20; i++) { data.setUint8(28 + i, infoHash[i]); }
    final pid = _generatePeerId();
    for (var i = 0; i < 20; i++) { data.setUint8(48 + i, pid[i]); }
    return data.buffer.asUint8List();
  }

  void _sendMessage(int id, Uint8List? payload) {
    if (_socket == null) return;
    final len = 1 + (payload?.length ?? 0);
    final data = ByteData(4 + len);
    data.setUint32(0, len, Endian.big);
    data.setUint8(4, id);
    if (payload != null) {
      for (var i = 0; i < payload.length; i++) {
        data.setUint8(5 + i, payload[i]);
      }
    }
    _socket!.add(data.buffer.asUint8List());
  }

  void _sendRequestMessage(int index, int begin, int length) {
    final payload = ByteData(12);
    payload.setUint32(0, index, Endian.big);
    payload.setUint32(4, begin, Endian.big);
    payload.setUint32(8, length, Endian.big);
    _sendMessage(PeerWireMessage.request, payload.buffer.asUint8List());
  }

  Uint8List _buildExtendedMessage(int extId, Uint8List payload) {
    final msgPayload = Uint8List(1 + payload.length);
    msgPayload[0] = extId;
    msgPayload.setRange(1, 1 + payload.length, payload);
    final len = 1 + msgPayload.length;
    final data = ByteData(4 + len);
    data.setUint32(0, len, Endian.big);
    data.setUint8(4, PeerWireMessage.extended);
    for (var i = 0; i < msgPayload.length; i++) {
      data.setUint8(5 + i, msgPayload[i]);
    }
    return data.buffer.asUint8List();
  }

  Future<Uint8List?> _readExactly(Socket socket, int n, Duration timeout) async {
    final completer = Completer<Uint8List?>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(null);
    });
    final collected = <int>[];
    socket.listen(
      (data) {
        collected.addAll(data);
        if (collected.length >= n) {
          if (!completer.isCompleted) {
            completer.complete(Uint8List.fromList(collected.sublist(0, n)));
          }
        }
      },
      onError: (_) {
        if (!completer.isCompleted) completer.complete(null);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    final result = await completer.future;
    timer.cancel();
    return result;
  }

  Future<void> _requestMetadataPieces() async {
    if (_metadataSize <= 0) return;
    final pieceCount = (_metadataSize + 16383) ~/ 16384;
    for (var i = 0; i < pieceCount; i++) {
      final payload = utf8.encode(json.encode({'msg_type': 0, 'piece': i}));
      _socket!.add(_buildExtendedMessage(_utMetadataId, payload));
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  Uint8List _hexToBytes(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }

  Uint8List _generatePeerId() {
    final id = Uint8List(20);
    id[0] = 84; id[1] = 70; id[2] = 45; id[3] = 84; id[4] = 70;
    for (var i = 5; i < 20; i++) { id[i] = _random.nextInt(256); }
    return id;
  }

  void _cleanup() {
    _connected = false;
    if (!_metadataDone.isCompleted) _metadataDone.complete();
  }

  void close() {
    _cleanup();
    _socket?.close();
    _socket = null;
  }

  bool get isConnected => _connected && _socket != null;
  bool get isPeerChoking => _peerChoking;
  int get metadataSize => _metadataSize;
}
