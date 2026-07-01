class SeedrAccount {
  final int usedStorage;
  final int totalStorage;
  final String? email;

  const SeedrAccount({
    required this.usedStorage,
    required this.totalStorage,
    this.email,
  });

  double get usagePercent => totalStorage > 0 ? usedStorage / totalStorage : 0;
  String get formattedUsed => _formatBytes(usedStorage);
  String get formattedTotal => _formatBytes(totalStorage);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class SeedrFolder {
  final String id;
  final String name;
  final int fileCount;
  final int size;

  SeedrFolder({
    required this.id,
    required this.name,
    this.fileCount = 0,
    this.size = 0,
  });

  String get formattedSize => _formatBytes(size);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class SeedrFile {
  final String id;
  final String name;
  final int size;
  final String? downloadUrl;
  final String? streamUrl;

  SeedrFile({
    required this.id,
    required this.name,
    required this.size,
    this.downloadUrl,
    this.streamUrl,
  });

  String get formattedSize => _formatBytes(size);
  String get extension => name.contains('.') ? name.split('.').last : '';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

enum SeedrItemType { folder, file, torrent }

class SeedrItem {
  final String id;
  final String name;
  final int size;
  final SeedrItemType type;
  final int progress;
  final String? downloadUrl;
  final int fileCount;

  const SeedrItem({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    this.progress = 0,
    this.downloadUrl,
    this.fileCount = 0,
  });

  String get formattedSize => _formatBytes(size);
  String get formattedProgress => '$progress%';
  bool get isFolder => type == SeedrItemType.folder;

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class SeedrTorrent {
  final String id;
  final String name;
  final int size;
  final int progress;
  final String? downloadUrl;

  SeedrTorrent({
    required this.id,
    required this.name,
    required this.size,
    this.progress = 0,
    this.downloadUrl,
  });

  bool get isReady => progress >= 100;
  String get formattedSize => _formatBytes(size);
  String get formattedProgress => '$progress%';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
