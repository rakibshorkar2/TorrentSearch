class AppSettings {
  final bool useDarkMode;
  final bool followSystemTheme;
  final bool wifiOnly;
  final bool autoImportMagnet;
  final bool notificationsEnabled;
  final int maxConcurrentDownloads;
  final int maxPeers;
  final int maxConnections;
  final int downloadSpeedLimit;
  final int uploadSpeedLimit;
  final int connectionTimeout;
  final String? socks5ProxyHost;
  final int? socks5ProxyPort;
  final String? socks5ProxyUser;
  final String? socks5ProxyPass;

  const AppSettings({
    this.useDarkMode = true,
    this.followSystemTheme = true,
    this.wifiOnly = false,
    this.autoImportMagnet = true,
    this.notificationsEnabled = true,
    this.maxConcurrentDownloads = 3,
    this.maxPeers = 50,
    this.maxConnections = 50,
    this.downloadSpeedLimit = 0,
    this.uploadSpeedLimit = 0,
    this.connectionTimeout = 10,
    this.socks5ProxyHost,
    this.socks5ProxyPort,
    this.socks5ProxyUser,
    this.socks5ProxyPass,
  });

  AppSettings copyWith({
    bool? useDarkMode,
    bool? followSystemTheme,
    bool? wifiOnly,
    bool? autoImportMagnet,
    bool? notificationsEnabled,
    int? maxConcurrentDownloads,
    int? maxPeers,
    int? maxConnections,
    int? downloadSpeedLimit,
    int? uploadSpeedLimit,
    int? connectionTimeout,
    String? socks5ProxyHost,
    int? socks5ProxyPort,
    String? socks5ProxyUser,
    String? socks5ProxyPass,
  }) {
    return AppSettings(
      useDarkMode: useDarkMode ?? this.useDarkMode,
      followSystemTheme: followSystemTheme ?? this.followSystemTheme,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      autoImportMagnet: autoImportMagnet ?? this.autoImportMagnet,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      maxConcurrentDownloads: maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      maxPeers: maxPeers ?? this.maxPeers,
      maxConnections: maxConnections ?? this.maxConnections,
      downloadSpeedLimit: downloadSpeedLimit ?? this.downloadSpeedLimit,
      uploadSpeedLimit: uploadSpeedLimit ?? this.uploadSpeedLimit,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      socks5ProxyHost: socks5ProxyHost ?? this.socks5ProxyHost,
      socks5ProxyPort: socks5ProxyPort ?? this.socks5ProxyPort,
      socks5ProxyUser: socks5ProxyUser ?? this.socks5ProxyUser,
      socks5ProxyPass: socks5ProxyPass ?? this.socks5ProxyPass,
    );
  }
}
