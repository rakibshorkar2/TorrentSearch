class TorrentInfo {
  final String id;
  final String title;
  final String? magnetUri;
  final String? infoHash;
  final int size;
  final int seeders;
  final int leechers;
  final DateTime uploadDate;
  final String? category;
  final String? fileUrl;

  TorrentInfo({
    required this.id,
    required this.title,
    this.magnetUri,
    this.infoHash,
    required this.size,
    required this.seeders,
    required this.leechers,
    required this.uploadDate,
    this.category,
    this.fileUrl,
  });

  String get formattedSize => _formatBytes(size);
  String get health => seeders > 0
      ? (leechers > 0 ? (seeders / leechers).toStringAsFixed(1) : 'Excellent')
      : 'Dead';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

enum DownloadStatus {
  downloading,
  seeding,
  paused,
  stopped,
  completed,
  error,
  verifying,
  queued;

  bool get isActive => this == downloading || this == seeding || this == queued;
  bool get isFinished => this == completed;
  bool get isStopped => this == paused || this == stopped;
}

class DownloadTask {
  final String id;
  final String title;
  final String? infoHash;
  final String? magnetUri;
  final String? torrentPath;
  final int totalSize;
  final int downloadedBytes;
  final int uploadedBytes;
  final DownloadStatus status;
  final double progress;
  final int downloadSpeed;
  final int uploadSpeed;
  final int peers;
  final int seeders;
  final String savePath;
  final DateTime addedAt;
  final DateTime? completedAt;
  final Duration? eta;
  final List<int> selectedFileIndices;
  final int? downloadLimit;
  final int? uploadLimit;

  const DownloadTask({
    required this.id,
    required this.title,
    this.infoHash,
    this.magnetUri,
    this.torrentPath,
    required this.totalSize,
    this.downloadedBytes = 0,
    this.uploadedBytes = 0,
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.downloadSpeed = 0,
    this.uploadSpeed = 0,
    this.peers = 0,
    this.seeders = 0,
    required this.savePath,
    required this.addedAt,
    this.completedAt,
    this.eta,
    this.selectedFileIndices = const [],
    this.downloadLimit,
    this.uploadLimit,
  });

  String get formattedProgress => '${(progress * 100).toStringAsFixed(1)}%';
  String get formattedDownloaded => _formatBytes(downloadedBytes);
  String get formattedTotal => _formatBytes(totalSize);
  String get formattedSpeed => '${_formatBytes(downloadSpeed)}/s';
  String get formattedUploadSpeed => '${_formatBytes(uploadSpeed)}/s';
  String get remainingFormatted => _formatBytes(totalSize - downloadedBytes);

  DownloadTask copyWith({
    String? id,
    String? title,
    String? infoHash,
    String? magnetUri,
    String? torrentPath,
    int? totalSize,
    int? downloadedBytes,
    int? uploadedBytes,
    DownloadStatus? status,
    double? progress,
    int? downloadSpeed,
    int? uploadSpeed,
    int? peers,
    int? seeders,
    String? savePath,
    DateTime? addedAt,
    DateTime? completedAt,
    Duration? eta,
    List<int>? selectedFileIndices,
    int? downloadLimit,
    int? uploadLimit,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      title: title ?? this.title,
      infoHash: infoHash ?? this.infoHash,
      magnetUri: magnetUri ?? this.magnetUri,
      torrentPath: torrentPath ?? this.torrentPath,
      totalSize: totalSize ?? this.totalSize,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      peers: peers ?? this.peers,
      seeders: seeders ?? this.seeders,
      savePath: savePath ?? this.savePath,
      addedAt: addedAt ?? this.addedAt,
      completedAt: completedAt ?? this.completedAt,
      eta: eta ?? this.eta,
      selectedFileIndices: selectedFileIndices ?? this.selectedFileIndices,
      downloadLimit: downloadLimit ?? this.downloadLimit,
      uploadLimit: uploadLimit ?? this.uploadLimit,
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
