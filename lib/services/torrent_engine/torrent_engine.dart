import 'dart:async';

enum TorrentState { queued, checking, downloading, seeding, finished, error, paused }

class TorrentStatus {
  final String id;
  final String name;
  final TorrentState state;
  final double progress;
  final int downloadRate;
  final int uploadRate;
  final int totalDownloaded;
  final int totalSize;
  final int seeders;
  final int leechers;
  final int peers;
  final String? errorMessage;

  const TorrentStatus({
    required this.id,
    required this.name,
    required this.state,
    this.progress = 0,
    this.downloadRate = 0,
    this.uploadRate = 0,
    this.totalDownloaded = 0,
    this.totalSize = 0,
    this.seeders = 0,
    this.leechers = 0,
    this.peers = 0,
    this.errorMessage,
  });

  TorrentStatus copyWith({
    String? id,
    String? name,
    TorrentState? state,
    double? progress,
    int? downloadRate,
    int? uploadRate,
    int? totalDownloaded,
    int? totalSize,
    int? seeders,
    int? leechers,
    int? peers,
    String? errorMessage,
  }) {
    return TorrentStatus(
      id: id ?? this.id,
      name: name ?? this.name,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      downloadRate: downloadRate ?? this.downloadRate,
      uploadRate: uploadRate ?? this.uploadRate,
      totalDownloaded: totalDownloaded ?? this.totalDownloaded,
      totalSize: totalSize ?? this.totalSize,
      seeders: seeders ?? this.seeders,
      leechers: leechers ?? this.leechers,
      peers: peers ?? this.peers,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

abstract class TorrentEngine {
  Future<void> initialize({required String savePath});
  Future<String> addMagnet(String magnetUri, {String? name, String? savePath});
  Future<String> addTorrentFile(String filePath, {String? name, String? savePath});
  void remove(String id);
  void pause(String id);
  void resume(String id);
  TorrentStatus? status(String id);
  List<TorrentStatus> allStatuses();
  Stream<TorrentStatus> updates();
  Future<void> shutdown();
}
