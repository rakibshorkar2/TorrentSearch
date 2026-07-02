enum HistoryItemType {
  magnetLink,
  download,
}

class HistoryItem {
  final String id;
  final String title;
  final String? magnetUri;
  final String? infoHash;
  final int? totalSize;
  final HistoryItemType type;
  final DateTime addedAt;
  final DateTime? completedAt;
  final bool downloadCompleted;

  const HistoryItem({
    required this.id,
    required this.title,
    this.magnetUri,
    this.infoHash,
    this.totalSize,
    required this.type,
    required this.addedAt,
    this.completedAt,
    this.downloadCompleted = false,
  });

  HistoryItem copyWith({
    String? id,
    String? title,
    String? magnetUri,
    String? infoHash,
    int? totalSize,
    HistoryItemType? type,
    DateTime? addedAt,
    DateTime? completedAt,
    bool? downloadCompleted,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      magnetUri: magnetUri ?? this.magnetUri,
      infoHash: infoHash ?? this.infoHash,
      totalSize: totalSize ?? this.totalSize,
      type: type ?? this.type,
      addedAt: addedAt ?? this.addedAt,
      completedAt: completedAt ?? this.completedAt,
      downloadCompleted: downloadCompleted ?? this.downloadCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'magnetUri': magnetUri,
      'infoHash': infoHash,
      'totalSize': totalSize,
      'type': type.index,
      'addedAt': addedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'downloadCompleted': downloadCompleted,
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      magnetUri: map['magnetUri'] as String?,
      infoHash: map['infoHash'] as String?,
      totalSize: map['totalSize'] as int?,
      type: HistoryItemType.values[map['type'] as int? ?? 0],
      addedAt: DateTime.tryParse(map['addedAt']?.toString() ?? '') ?? DateTime.now(),
      completedAt: DateTime.tryParse(map['completedAt']?.toString() ?? ''),
      downloadCompleted: map['downloadCompleted'] as bool? ?? false,
    );
  }

  String get formattedSize {
    if (totalSize == null || totalSize! <= 0) return '';
    return _formatBytes(totalSize!);
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
