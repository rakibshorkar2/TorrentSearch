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
  final String? source;
  final String? quality;
  final bool isVideo;
  final bool isAudio;
  final bool isGame;
  final bool isApp;

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
    this.source,
    this.quality,
    this.isVideo = false,
    this.isAudio = false,
    this.isGame = false,
    this.isApp = false,
  });

  factory TorrentInfo.fromJson(Map<String, dynamic> json) {
    final title = (json['name'] ?? json['title'] ?? 'Unknown').toString();
    return TorrentInfo(
      id: (json['id'] ?? '').toString(),
      title: title,
      magnetUri: json['magnet']?.toString(),
      infoHash: json['info_hash']?.toString(),
      size: int.tryParse(json['size']?.toString() ?? '0') ?? 0,
      seeders: int.tryParse(json['seeders']?.toString() ?? '0') ?? 0,
      leechers: int.tryParse(json['leechers']?.toString() ?? '0') ?? 0,
      uploadDate: DateTime.tryParse(json['added']?.toString() ?? '') ?? DateTime.now(),
      category: json['category']?.toString(),
      fileUrl: json['download_url']?.toString(),
      source: json['source']?.toString(),
      quality: parseQuality(title),
      isVideo: _isVideo(title, json['category']?.toString()),
      isAudio: _isAudio(title, json['category']?.toString()),
      isGame: _isGame(title, json['category']?.toString()),
      isApp: _isApp(title, json['category']?.toString()),
    );
  }

  static String? parseQuality(String title) {
    final lower = title.toLowerCase();
    final qualities = ['2160p', '1080p', '720p', '480p', '4k', 'uhd'];
    for (final q in qualities) {
      if (lower.contains(q)) return q;
    }
    if (lower.contains('hdr') || lower.contains('bluray') || lower.contains('blu-ray')) return 'HD';
    if (lower.contains('hdrip') || lower.contains('webrip') || lower.contains('web-dl')) return 'HD';
    if (lower.contains('dvdrip') || lower.contains('dvd')) return 'SD';
    return null;
  }

  static bool _isVideo(String title, String? category) {
    if (category == '200' || category == '201' || category == '202' || category == '203') return true;
    final lower = title.toLowerCase();
    return lower.contains('movie') || lower.contains('film') || lower.contains('episode') ||
           lower.contains('s0') || lower.contains('s1') || lower.contains('s2') ||
           lower.contains('s3') || lower.contains('s4') || lower.contains('s5') ||
           lower.contains('s6') || lower.contains('s7') || lower.contains('s8') || lower.contains('s9');
  }

  static bool _isAudio(String title, String? category) {
    if (category == '100' || category == '101') return true;
    final lower = title.toLowerCase();
    return lower.contains('mp3') || lower.contains('flac') || lower.contains('album') ||
           lower.contains('soundtrack') || lower.contains('ost');
  }

  static bool _isGame(String title, String? category) {
    if (category == '400' || category == '401' || category == '402') return true;
    final lower = title.toLowerCase();
    return lower.contains('game') || lower.contains('iso') || lower.contains('ps4') ||
           lower.contains('ps5') || lower.contains('xbox') || lower.contains('switch') ||
           lower.contains('nintendo') || lower.contains('steam');
  }

  static bool _isApp(String title, String? category) {
    if (category == '300' || category == '301' || category == '302' || category == '303') return true;
    final lower = title.toLowerCase();
    return lower.contains('windows') || lower.contains('macos') || lower.contains('linux') ||
           lower.contains('software') || lower.contains('app') || lower.contains('crack');
  }

  String get formattedSize => _formatBytes(size);

  String get health {
    if (seeders <= 0) return 'Dead';
    if (leechers <= 0) return 'Excellent';
    final ratio = seeders / leechers;
    if (ratio >= 5) return 'Excellent';
    if (ratio >= 2) return 'Good';
    if (ratio >= 1) return 'Ok';
    return 'Poor';
  }

  double get healthRatio {
    if (seeders <= 0) return 0;
    if (leechers <= 0) return 5;
    return (seeders / leechers).clamp(0, 5);
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  TorrentInfo copyWith({
    String? id,
    String? title,
    String? magnetUri,
    String? infoHash,
    int? size,
    int? seeders,
    int? leechers,
    DateTime? uploadDate,
    String? category,
    String? fileUrl,
    String? source,
    String? quality,
    bool? isVideo,
    bool? isAudio,
    bool? isGame,
    bool? isApp,
  }) {
    return TorrentInfo(
      id: id ?? this.id,
      title: title ?? this.title,
      magnetUri: magnetUri ?? this.magnetUri,
      infoHash: infoHash ?? this.infoHash,
      size: size ?? this.size,
      seeders: seeders ?? this.seeders,
      leechers: leechers ?? this.leechers,
      uploadDate: uploadDate ?? this.uploadDate,
      category: category ?? this.category,
      fileUrl: fileUrl ?? this.fileUrl,
      source: source ?? this.source,
      quality: quality ?? this.quality,
      isVideo: isVideo ?? this.isVideo,
      isAudio: isAudio ?? this.isAudio,
      isGame: isGame ?? this.isGame,
      isApp: isApp ?? this.isApp,
    );
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

enum DownloadPriority { low, normal, high }

class DownloadTask {
  final String id;
  final String title;
  final String? infoHash;
  final String? magnetUri;
  final String? torrentPath;
  final String? downloadUrl;
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
  final DownloadPriority priority;

  const DownloadTask({
    required this.id,
    required this.title,
    this.infoHash,
    this.magnetUri,
    this.torrentPath,
    this.downloadUrl,
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
    this.priority = DownloadPriority.normal,
  });

  String get formattedProgress => '${(progress * 100).toStringAsFixed(1)}%';
  String get formattedDownloaded => _formatBytes(downloadedBytes);
  String get formattedTotal => _formatBytes(totalSize);
  String get formattedSpeed => '${_formatBytes(downloadSpeed)}/s';
  String get formattedUploadSpeed => '${_formatBytes(uploadSpeed)}/s';
  String get remainingFormatted => _formatBytes((totalSize - downloadedBytes).clamp(0, totalSize));

  DownloadTask copyWith({
    String? id,
    String? title,
    String? infoHash,
    String? magnetUri,
    String? torrentPath,
    String? downloadUrl,
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
    DownloadPriority? priority,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      title: title ?? this.title,
      infoHash: infoHash ?? this.infoHash,
      magnetUri: magnetUri ?? this.magnetUri,
      torrentPath: torrentPath ?? this.torrentPath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
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
      priority: priority ?? this.priority,
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
