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
    );
  }
}
