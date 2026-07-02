class AppConstants {
  static const String appName = 'TorrentFlow';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';
  static const String defaultTorrentSearchUrl = 'https://apibay.org';

  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 3);
  static const Duration maxRetryDelay = Duration(seconds: 30);
  static const int maxRetries = 3;

  static const int maxConcurrentDownloads = 5;
  static const int maxConnectionsPerTorrent = 50;
  static const int maxPeersPerTorrent = 50;
  static const int downloadBufferSize = 65536;

  static const String hiveBoxSettings = 'settings';
  static const String hiveBoxDownloads = 'downloads';
  static const String hiveBoxSearchHistory = 'search_history';
  static const String hiveBoxSeedrCache = 'seedr_cache';
  static const String hiveBoxHistory = 'history';

  static const String keychainSeedrToken = 'seedr_token';
  static const String keychainProxSettings = 'proxy_settings';

  static const String magnetScheme = 'magnet';
  static const String torrentExtension = '.torrent';
}
