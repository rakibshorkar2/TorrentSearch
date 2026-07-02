import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'torrent_engine.dart';

final class _TorrentStatusC extends Struct {
  @Double()
  external double progress;

  @Int64()
  external int downloadRate;

  @Int64()
  external int uploadRate;

  @Int64()
  external int totalDownload;

  @Int64()
  external int totalUpload;

  @Int64()
  external int totalSize;

  @Int32()
  external int seeders;

  @Int32()
  external int leechers;

  @Int32()
  external int peers;

  @Int32()
  external int state;

  @Array(256)
  external Array<Uint8> error;
}

final class _TorrentAlertC extends Struct {
  @Int32()
  external int handleId;

  external _TorrentStatusC status;

  @Array(256)
  external Array<Uint8> name;
}

typedef _SessionCreateC = Pointer<Void> Function(Pointer<Utf8>);
typedef _SessionCreateDart = Pointer<Void> Function(Pointer<Utf8>);

typedef _SessionDestroyC = Void Function(Pointer<Void>);
typedef _SessionDestroyDart = void Function(Pointer<Void>);

typedef _AddMagnetC = Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);
typedef _AddMagnetDart = int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);

typedef _AddTorrentFileC = Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);
typedef _AddTorrentFileDart = int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);

typedef _RemoveC = Void Function(Pointer<Void>, Int32);
typedef _RemoveDart = void Function(Pointer<Void>, int);

typedef _PauseC = Void Function(Pointer<Void>, Int32);
typedef _PauseDart = void Function(Pointer<Void>, int);

typedef _ResumeC = Void Function(Pointer<Void>, Int32);
typedef _ResumeDart = void Function(Pointer<Void>, int);

typedef _PopAlertsC = Int32 Function(Pointer<Void>, Pointer<_TorrentAlertC>, Int32);
typedef _PopAlertsDart = int Function(Pointer<Void>, Pointer<_TorrentAlertC>, int);

typedef _GetStatusC = Int32 Function(Pointer<Void>, Int32, Pointer<_TorrentStatusC>);
typedef _GetStatusDart = int Function(Pointer<Void>, int, Pointer<_TorrentStatusC>);

typedef _GetAllStatusesC = Int32 Function(Pointer<Void>, Pointer<_TorrentStatusC>, Int32);
typedef _GetAllStatusesDart = int Function(Pointer<Void>, Pointer<_TorrentStatusC>, int);

class LibTorrentEngine implements TorrentEngine {
  late final DynamicLibrary _lib;
  late final Pointer<Void> _session;
  final _updateController = StreamController<TorrentStatus>.broadcast();
  Timer? _pollTimer;
  bool _initialized = false;
  String _savePath = '';

  late final _SessionCreateDart _sessionCreate;
  late final _SessionDestroyDart _sessionDestroy;
  late final _AddMagnetDart _addMagnet;
  late final _AddTorrentFileDart _addTorrentFile;
  late final _RemoveDart _remove;
  late final _PauseDart _pause;
  late final _ResumeDart _resume;
  late final _PopAlertsDart _popAlerts;
  late final _GetStatusDart _getStatus;
  late final _GetAllStatusesDart _getAllStatuses;

  @override
  Future<void> initialize({required String savePath}) async {
    _savePath = savePath;
    _lib = _loadLibrary();
    _bindFunctions();

    final pathPtr = savePath.toNativeUtf8();
    _session = _sessionCreate(pathPtr);
    calloc.free(pathPtr);

    _initialized = true;
    _startPolling();
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isIOS) return DynamicLibrary.process();
    throw UnsupportedError('LibTorrentEngine requires iOS');
  }

  void _bindFunctions() {
    _sessionCreate = _lib.lookupFunction<_SessionCreateC, _SessionCreateDart>('torrent_session_create');
    _sessionDestroy = _lib.lookupFunction<_SessionDestroyC, _SessionDestroyDart>('torrent_session_destroy');
    _addMagnet = _lib.lookupFunction<_AddMagnetC, _AddMagnetDart>('torrent_session_add_magnet');
    _addTorrentFile = _lib.lookupFunction<_AddTorrentFileC, _AddTorrentFileDart>('torrent_session_add_torrent_file');
    _remove = _lib.lookupFunction<_RemoveC, _RemoveDart>('torrent_session_remove');
    _pause = _lib.lookupFunction<_PauseC, _PauseDart>('torrent_session_pause');
    _resume = _lib.lookupFunction<_ResumeC, _ResumeDart>('torrent_session_resume');
    _popAlerts = _lib.lookupFunction<_PopAlertsC, _PopAlertsDart>('torrent_session_pop_alerts');
    _getStatus = _lib.lookupFunction<_GetStatusC, _GetStatusDart>('torrent_session_get_status');
    _getAllStatuses = _lib.lookupFunction<_GetAllStatusesC, _GetAllStatusesDart>('torrent_session_get_all_statuses');
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _pollAlerts();
    });
  }

  void _pollAlerts() {
    if (!_initialized) return;

    const maxAlerts = 64;
    final alertsPtr = calloc<_TorrentAlertC>(maxAlerts);
    try {
      final count = _popAlerts(_session, alertsPtr, maxAlerts);
      for (var i = 0; i < count; i++) {
        final alert = (alertsPtr + i).ref;
        final name = alert.name;
        _updateController.add(TorrentStatus(
          id: alert.handleId.toString(),
          name: _readCString(name),
          state: _fromCState(alert.status.state),
          progress: alert.status.progress,
          downloadRate: alert.status.downloadRate,
          uploadRate: alert.status.uploadRate,
          totalDownloaded: alert.status.totalDownload,
          totalSize: alert.status.totalSize,
          seeders: alert.status.seeders,
          leechers: alert.status.leechers,
          peers: alert.status.peers,
          errorMessage: alert.status.state == -1 ? _readCString(alert.status.error) : null,
        ));
      }
    } finally {
      calloc.free(alertsPtr);
    }
  }

  static String _readCString(Array<Uint8> arr) {
    final bytes = <int>[];
    for (var i = 0; i < 256; i++) {
      if (arr[i] == 0) break;
      bytes.add(arr[i]);
    }
    return String.fromCharCodes(bytes);
  }

  static TorrentState _fromCState(int state) {
    switch (state) {
      case 0: return TorrentState.queued;
      case 1: return TorrentState.checking;
      case 2: return TorrentState.downloading;
      case 3: return TorrentState.downloading;
      case 4: return TorrentState.finished;
      case 5: return TorrentState.seeding;
      default: return TorrentState.error;
    }
  }

  static TorrentStatus _fromCStatus(_TorrentStatusC c) {
    return TorrentStatus(
      id: '',
      name: '',
      state: _fromCState(c.state),
      progress: c.progress,
      downloadRate: c.downloadRate,
      uploadRate: c.uploadRate,
      totalDownloaded: c.totalDownload,
      totalSize: c.totalSize,
      seeders: c.seeders,
      leechers: c.leechers,
      peers: c.peers,
    );
  }

  @override
  Future<String> addMagnet(String magnetUri, {String? name}) async {
    final uriPtr = magnetUri.toNativeUtf8();
    final pathPtr = _savePath.toNativeUtf8();
    try {
      final id = _addMagnet(_session, uriPtr, pathPtr);
      if (id < 0) throw Exception('Failed to add magnet');
      return id.toString();
    } finally {
      calloc.free(uriPtr);
      calloc.free(pathPtr);
    }
  }

  @override
  Future<String> addTorrentFile(String filePath, {String? name}) async {
    final filePtr = filePath.toNativeUtf8();
    final pathPtr = _savePath.toNativeUtf8();
    try {
      final id = _addTorrentFile(_session, filePtr, pathPtr);
      if (id < 0) throw Exception('Failed to add torrent file');
      return id.toString();
    } finally {
      calloc.free(filePtr);
      calloc.free(pathPtr);
    }
  }

  @override
  void remove(String id) {
    _remove(_session, int.tryParse(id) ?? -1);
  }

  @override
  void pause(String id) {
    _pause(_session, int.tryParse(id) ?? -1);
  }

  @override
  void resume(String id) {
    _resume(_session, int.tryParse(id) ?? -1);
  }

  @override
  TorrentStatus? status(String id) {
    final statusC = calloc<_TorrentStatusC>();
    try {
      final ret = _getStatus(_session, int.tryParse(id) ?? -1, statusC);
      if (ret < 0) return null;
      return _fromCStatus(statusC.ref);
    } finally {
      calloc.free(statusC);
    }
  }

  @override
  List<TorrentStatus> allStatuses() {
    const maxCount = 64;
    final statusesPtr = calloc<_TorrentStatusC>(maxCount);
    try {
      final count = _getAllStatuses(_session, statusesPtr, maxCount);
      final result = <TorrentStatus>[];
      for (var i = 0; i < count; i++) {
        final c = (statusesPtr + i).ref;
        result.add(TorrentStatus(
          id: i.toString(),
          name: '',
          state: _fromCState(c.state),
          progress: c.progress,
          downloadRate: c.downloadRate,
          uploadRate: c.uploadRate,
          totalDownloaded: c.totalDownload,
          totalSize: c.totalSize,
          seeders: c.seeders,
          leechers: c.leechers,
          peers: c.peers,
        ));
      }
      return result;
    } finally {
      calloc.free(statusesPtr);
    }
  }

  @override
  Stream<TorrentStatus> updates() => _updateController.stream;

  @override
  Future<void> shutdown() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_initialized) {
      _sessionDestroy(_session);
      _initialized = false;
    }
    await _updateController.close();
  }
}
