import Flutter
import UIKit
import UserNotifications
import Network

class TorrentFlowNativeService: NSObject {
  private var channel: FlutterMethodChannel
  private var backgroundSessionIdentifier = "com.torrentflow.bg"
  private var networkMonitor: NWPathMonitor?
  private var isWifiConnected = true
  private var backgroundCompletionHandler: (() -> Void)?

  init(messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(name: "com.torrentflow/native", binaryMessenger: messenger)
    super.init()
    self.channel.setMethodCallHandler(handle)
    setupNetworkMonitor()
  }

  // MARK: - Setup

  private func setupNetworkMonitor() {
    networkMonitor = NWPathMonitor()
    networkMonitor?.pathUpdateHandler = { [weak self] path in
      self?.isWifiConnected = path.usesInterfaceType(.wifi)
    }
    networkMonitor?.start(queue: DispatchQueue.global(qos: .background))
  }

  // MARK: - Method Channel Handler

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getNetworkStatus":
      result(["isWifi": isWifiConnected, "isExpensive": false])
    case "requestNotificationPermission":
      requestNotificationPermission(result: result)
    case "showLocalNotification":
      showLocalNotification(call, result: result)
    case "getKeychainValue":
      getKeychainValue(call, result: result)
    case "setKeychainValue":
      setKeychainValue(call, result: result)
    case "deleteKeychainValue":
      deleteKeychainValue(call, result: result)
    case "getDeviceModel":
      result(getDeviceModel())
    case "getThermalState":
      result(ProcessInfo.processInfo.thermalState.rawValue)
    case "getStorageInfo":
      result(getStorageInfo())
    case "registerBackgroundTask":
      result(true)
    case "unregisterBackgroundTask":
      result(true)
    case "scheduleBackgroundDownload":
      scheduleBackgroundDownload(call, result: result)
    case "enableBackgroundMode":
      UIApplication.shared.setMinimumBackgroundFetchInterval(
        UIApplication.backgroundFetchIntervalMinimum)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Notifications

  private func requestNotificationPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
        DispatchQueue.main.async { result(granted) }
      }
  }

  private func showLocalNotification(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let title = args["title"] as? String,
          let body = args["body"] as? String else {
      result(nil); return
    }

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let request = UNNotificationRequest(
      identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)
    result(nil)
  }

  // MARK: - Keychain

  private func getKeychainValue(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let key = (call.arguments as? [String: Any])?["key"] as? String,
          let data = KeychainHelper.load(key: key) else {
      result(nil); return
    }
    result(String(data: data, encoding: .utf8))
  }

  private func setKeychainValue(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let key = args["key"] as? String,
          let value = args["value"] as? String,
          let data = value.data(using: .utf8) else {
      result(FlutterError(code: "INVALID", message: "Invalid args", details: nil))
      return
    }
    KeychainHelper.save(key: key, data: data)
    result(nil)
  }

  private func deleteKeychainValue(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let key = (call.arguments as? [String: Any])?["key"] as? String else {
      result(nil); return
    }
    KeychainHelper.delete(key: key)
    result(nil)
  }

  // MARK: - Device

  private func getDeviceModel() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    return withUnsafePointer(to: &systemInfo.machine) {
      String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
    }
  }

  private func getStorageInfo() -> [String: Int64] {
    do {
      let attrs = try FileManager.default
        .attributesOfFileSystem(forPath: NSHomeDirectory())
      return [
        "free": attrs[.systemFreeSize] as? Int64 ?? 0,
        "total": attrs[.systemSize] as? Int64 ?? 0,
      ]
    } catch {
      return [:]
    }
  }

  // MARK: - Background Download

  private func scheduleBackgroundDownload(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let urlString = args["url"] as? String,
          let url = URL(string: urlString) else {
      result(FlutterError(code: "INVALID", message: "Invalid URL", details: nil))
      return
    }

    let config = URLSessionConfiguration
      .background(withIdentifier: "\(backgroundSessionIdentifier).\(Date().timeIntervalSince1970)")
    config.sessionSendsLaunchEvents = true
    config.isDiscretionary = false

    let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    session.downloadTask(with: url).resume()
    result(true)
  }

  func handleBackgroundURLSession(identifier: String, completionHandler: @escaping () -> Void) {
    backgroundCompletionHandler = completionHandler
    _ = URLSession(
      configuration: URLSessionConfiguration.background(withIdentifier: identifier),
      delegate: self, delegateQueue: nil)
  }
}

// MARK: - URLSession Download Delegate

extension TorrentFlowNativeService: URLSessionDownloadDelegate {
  func urlSession(_ session: URLSession,
                  downloadTask: URLSessionDownloadTask,
                  didFinishDownloadingTo location: URL) {
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let destination = documents
      .appendingPathComponent(downloadTask.originalRequest?.url?.lastPathComponent ?? "download")
    try? FileManager.default.removeItem(at: destination)
    try? FileManager.default.moveItem(at: location, to: destination)
  }

  func urlSession(_ session: URLSession,
                  task: URLSessionTask,
                  didCompleteWithError error: Error?) {
    if let handler = backgroundCompletionHandler {
      handler()
      backgroundCompletionHandler = nil
    }
  }
}

// MARK: - Keychain

struct KeychainHelper {
  static func save(key: String, data: Data) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecValueData as String: data,
    ]
    SecItemDelete(query as CFDictionary)
    SecItemAdd(query as CFDictionary, nil)
  }

  static func load(key: String) -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
    return item as? Data
  }

  static func delete(key: String) {
    SecItemDelete([kSecClass as String: kSecClassGenericPassword,
                   kSecAttrAccount as String: key] as CFDictionary)
  }
}
