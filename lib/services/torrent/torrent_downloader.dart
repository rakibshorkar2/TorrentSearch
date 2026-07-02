import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../../models/torrent.dart';
import 'magnet_link.dart';
import 'tracker_client.dart';
import 'peer_wire.dart';
import 'bencode.dart';

class TorrentDownloader {
  bool _cancelled = false;
  int _totalPieces = 0;
  int _downloadedPieces = 0;
  int _pieceLength = 0;
  int _totalSize = 0;
  final List<Uint8List> _pieceHashes = [];
  String _fileName = 'download';
  String _saveDir = '';

  void cancel() => _cancelled = true;

  Future<void> download({
    required String magnetUri,
    required String savePath,
    required String taskId,
    required StreamController<DownloadTask> controller,
  }) async {
    _saveDir = Directory(savePath).parent.path;

    final magnet = MagnetLink.parse(magnetUri);
    if (magnet == null) {
      _emitError(controller, taskId, 'Invalid magnet URI');
      return;
    }

    _fileName = magnet.displayName ?? 'unnamed';
    final infoHashHex = magnet.infoHashHex;

    _emitUpdate(controller, taskId,
      status: DownloadStatus.downloading,
      title: _fileName,
    );

    final peers = await _fetchPeers(magnet, infoHashHex);
    if (peers == null || peers.isEmpty || _cancelled) {
      _emitError(controller, taskId, 'No peers found');
      return;
    }

    final metadata = await _fetchMetadataFromPeers(peers, infoHashHex);
    if (metadata == null || _cancelled) {
      _emitError(controller, taskId, 'Could not retrieve torrent metadata');
      return;
    }

    if (!_parseMetadata(metadata)) {
      _emitError(controller, taskId, 'Failed to parse torrent metadata');
      return;
    }

    final filePath = '$_saveDir${Platform.pathSeparator}$_fileName';
    _emitUpdate(controller, taskId,
      totalSize: _totalSize,
      title: _fileName,
    );

    if (_cancelled) {
      _emitError(controller, taskId, 'Cancelled');
      return;
    }

    await _downloadPieces(peers, infoHashHex, filePath, taskId, controller);

    if (!_cancelled && _downloadedPieces >= _totalPieces) {
      _emitUpdate(controller, taskId,
        status: DownloadStatus.completed,
        progress: 1.0,
        downloadedBytes: _totalSize,
      );
    } else if (!_cancelled) {
      _emitError(controller, taskId, 'Download incomplete');
    }
  }

  Future<List<PeerInfo>?> _fetchPeers(MagnetLink magnet, String infoHashHex) async {
    final client = TrackerClient();
    final allPeers = <PeerInfo>[];
    for (final tracker in magnet.trackers) {
      if (_cancelled) break;
      try {
        final resp = await client.announce(
          trackerUrl: tracker,
          infoHashHex: infoHashHex,
          fileSize: 0,
        );
        if (resp != null && resp.peers.isNotEmpty) {
          allPeers.addAll(resp.peers);
          if (allPeers.length >= 50) break;
        }
      } catch (_) {}
    }
    allPeers.shuffle();
    return allPeers.take(30).toList();
  }

  Future<Uint8List?> _fetchMetadataFromPeers(List<PeerInfo> peers, String infoHashHex) async {
    for (final peer in peers) {
      if (_cancelled) break;
      final conn = PeerConnection();
      try {
        final ok = await conn.connect(peer.ip, peer.port, infoHashHex, 10);
        if (!ok) continue;
        final dummy = StreamController<Uint8List>();
        conn.startMessageLoop(dummy);
        final meta = await conn.fetchMetadata(infoHashHex);
        await dummy.close();
        conn.close();
        if (meta != null) return meta;
      } catch (_) {
        conn.close();
      }
    }
    return null;
  }

  Future<void> _downloadPieces(
    List<PeerInfo> peers,
    String infoHashHex,
    String filePath,
    String taskId,
    StreamController<DownloadTask> controller,
  ) async {
    for (final peer in peers) {
      if (_cancelled || _downloadedPieces >= _totalPieces) break;

      final conn = PeerConnection();
      StreamController<Uint8List>? pieceController;
      try {
        final ok = await conn.connect(peer.ip, peer.port, infoHashHex, 10);
        if (!ok) continue;

        for (var i = _downloadedPieces; i < _totalPieces && !_cancelled; i++) {
          pieceController = StreamController<Uint8List>();
          conn.startMessageLoop(pieceController);

          final pieceLen = (i == _totalPieces - 1)
              ? _totalSize - i * _pieceLength
              : _pieceLength;

          conn.requestPiece(i, 0, pieceLen);

          try {
            final pieceData = await pieceController.stream
              .timeout(const Duration(seconds: 30))
              .fold<BytesBuilder>(BytesBuilder(), (builder, block) {
                builder.add(block);
                return builder;
              });

            final assembled = pieceData.takeBytes();
            if (assembled.length >= pieceLen) {
              final pieceToWrite = assembled.length > pieceLen
                  ? Uint8List.fromList(assembled.sublist(0, pieceLen))
                  : Uint8List.fromList(assembled);

              if (_verifyPiece(pieceToWrite, i)) {
                await _writePiece(filePath, pieceToWrite, i);
                _downloadedPieces++;
                final progress = _totalPieces > 0 ? _downloadedPieces / _totalPieces : 0.0;
                _emitUpdate(controller, taskId,
                  progress: progress,
                  downloadedBytes: _downloadedPieces * _pieceLength,
                );
              }
            }
          } catch (_) {
            continue;
          } finally {
            await pieceController.close();
          }
        }

        conn.close();
      } catch (_) {
        conn.close();
      }
    }
  }

  bool _parseMetadata(Uint8List rawMetadata) {
    try {
      final b = Bencode.parseBytes(rawMetadata);
      _pieceLength = b.intValue('piece length', 262144);
      final piecesRaw = b.rawValue('pieces');
      for (var i = 0; i + 20 <= piecesRaw.length; i += 20) {
        _pieceHashes.add(piecesRaw.sublist(i, i + 20));
      }
      _totalSize = b.intValue('length');
      if (_totalSize == 0) {
        for (final f in b.listValue('files')) {
          _totalSize += f.intValue('length');
        }
      }
      _fileName = b.stringValueOf('name', _fileName);
      _totalPieces = _pieceHashes.length;
      return _totalPieces > 0 && _totalSize > 0;
    } catch (_) {
      return false;
    }
  }

  bool _verifyPiece(Uint8List data, int index) {
    if (index >= _pieceHashes.length) return false;
    final hash = sha1.convert(data).bytes;
    final expected = _pieceHashes[index];
    if (hash.length != expected.length) return false;
    for (var i = 0; i < hash.length; i++) {
      if (hash[i] != expected[i]) return false;
    }
    return true;
  }

  Future<void> _writePiece(String path, Uint8List data, int index) async {
    final file = await File(path).open(mode: FileMode.writeOnlyAppend);
    try {
      if (index > 0) {
        await file.setPosition(index * _pieceLength);
      }
      await file.writeFrom(data);
    } finally {
      await file.close();
    }
  }

  void _emitUpdate(StreamController<DownloadTask> controller, String taskId, {
    DownloadStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalSize,
    String? title,
  }) {
    if (controller.isClosed) return;
    controller.add(DownloadTask(
      id: taskId,
      title: title ?? _fileName,
      totalSize: totalSize ?? _totalSize,
      downloadedBytes: downloadedBytes ?? 0,
      savePath: '',
      addedAt: DateTime.now(),
      status: status ?? DownloadStatus.downloading,
      progress: progress ?? 0,
    ));
  }

  void _emitError(StreamController<DownloadTask> controller, String taskId, String error) {
    if (controller.isClosed) return;
    controller.add(DownloadTask(
      id: taskId,
      title: _fileName,
      totalSize: _totalSize,
      savePath: '',
      addedAt: DateTime.now(),
      status: DownloadStatus.error,
    ));
    if (!controller.isClosed) {
      controller.addError(Exception(error));
    }
  }
}
