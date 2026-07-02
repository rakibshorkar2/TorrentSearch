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
  final bool hapticFeedback;
  final bool confirmBeforeDownload;
  final bool autoDownloadCompletedSeedr;
  final bool saveSearchHistory;
  final int? screenAwakeMinutes;

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
    this.hapticFeedback = true,
    this.confirmBeforeDownload = true,
    this.autoDownloadCompletedSeedr = false,
    this.saveSearchHistory = true,
    this.screenAwakeMinutes,
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
    bool? hapticFeedback,
    bool? confirmBeforeDownload,
    bool? autoDownloadCompletedSeedr,
    bool? saveSearchHistory,
    int? screenAwakeMinutes,
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
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      confirmBeforeDownload: confirmBeforeDownload ?? this.confirmBeforeDownload,
      autoDownloadCompletedSeedr: autoDownloadCompletedSeedr ?? this.autoDownloadCompletedSeedr,
      saveSearchHistory: saveSearchHistory ?? this.saveSearchHistory,
      screenAwakeMinutes: screenAwakeMinutes ?? this.screenAwakeMinutes,
    );
  }
}
