import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/seedr_item.dart';
import '../core/constants/app_constants.dart';

class SeedrService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  String? _token;

  SeedrService()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://www.seedr.cc/api',
          connectTimeout: AppConstants.connectionTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
        )),
        _storage = const FlutterSecureStorage();

  Future<bool> isLoggedIn() async {
    _token ??= await _storage.read(key: AppConstants.keychainSeedrToken);
    if (_token != null && _token!.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      return true;
    }
    return false;
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      _token = response.data['token']?.toString();
      if (_token != null && _token!.isNotEmpty) {
        await _storage.write(key: AppConstants.keychainSeedrToken, value: _token!);
        _dio.options.headers['Authorization'] = 'Bearer $_token';
      } else {
        throw SeedrException('Login failed: Invalid credentials');
      }
    } on DioException catch (e) {
      throw SeedrException('Login failed: ${e.message}');
    }
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: AppConstants.keychainSeedrToken);
    _dio.options.headers.remove('Authorization');
  }

  Future<SeedrAccount> getAccount() async {
    _ensureAuth();
    try {
      final response = await _dio.get('/account');
      return SeedrAccount(
        usedStorage: response.data['space_used'] ?? 0,
        totalStorage: response.data['space_max'] ?? 0,
        email: response.data['email']?.toString(),
      );
    } on DioException catch (e) {
      throw SeedrException('Failed to get account: ${e.message}');
    }
  }

  Future<List<SeedrFolder>> getFolders() async {
    _ensureAuth();
    try {
      final response = await _dio.get('/folders');
      final list = response.data['folders'] as List? ?? [];
      return list.map((f) => SeedrFolder(
        id: f['id'].toString(),
        name: f['name'] ?? 'Unnamed',
        fileCount: f['file_count'] ?? 0,
        size: f['size'] ?? 0,
      )).toList();
    } on DioException catch (e) {
      throw SeedrException('Failed to get folders: ${e.message}');
    }
  }

  Future<List<SeedrFile>> getFiles(String folderId) async {
    _ensureAuth();
    try {
      final response = await _dio.get('/folder/$folderId');
      final list = response.data['files'] as List? ?? [];
      return list.map((f) => SeedrFile(
        id: f['id'].toString(),
        name: f['name'] ?? 'Unnamed',
        size: f['size'] ?? 0,
        downloadUrl: f['download_url']?.toString(),
        streamUrl: f['stream_url']?.toString(),
      )).toList();
    } on DioException catch (e) {
      throw SeedrException('Failed to get files: ${e.message}');
    }
  }

  Future<List<SeedrTorrent>> getTorrents() async {
    _ensureAuth();
    try {
      final response = await _dio.get('/torrents');
      final list = response.data['torrents'] as List? ?? [];
      return list.map((t) => SeedrTorrent(
        id: t['id'].toString(),
        name: t['name'] ?? 'Unnamed',
        size: t['size'] ?? 0,
        progress: t['progress'] ?? 0,
        downloadUrl: t['download_url']?.toString(),
      )).toList();
    } on DioException catch (e) {
      throw SeedrException('Failed to get torrents: ${e.message}');
    }
  }

  Future<List<SeedrItem>> listContents({int? folderId}) async {
    _ensureAuth();
    try {
      if (folderId != null) {
        final files = await getFiles(folderId.toString());
        return files.map((f) => SeedrItem(
          id: f.id,
          name: f.name,
          size: f.size,
          type: SeedrItemType.file,
          downloadUrl: f.downloadUrl,
        )).toList();
      }
      final folders = await getFolders();
      final torrents = await getTorrents();
      return [
        ...folders.map((f) => SeedrItem(
          id: f.id,
          name: f.name,
          size: f.size,
          type: SeedrItemType.folder,
          fileCount: f.fileCount,
        )),
        ...torrents.map((t) => SeedrItem(
          id: t.id,
          name: t.name,
          size: t.size,
          type: SeedrItemType.torrent,
          progress: t.progress,
          downloadUrl: t.downloadUrl,
        )),
      ];
    } on DioException catch (e) {
      throw SeedrException('Failed to list contents: ${e.message}');
    }
  }

  Future<void> addMagnet(String magnetUri) async {
    _ensureAuth();
    try {
      await _dio.post('/torrent/add_magnet', data: {'magnet': magnetUri});
    } on DioException catch (e) {
      throw SeedrException('Failed to add magnet: ${e.message}');
    }
  }

  Future<void> addTorrentFile(String filePath) async {
    _ensureAuth();
    try {
      final formData = FormData.fromMap({
        'torrent_file': await MultipartFile.fromFile(filePath),
      });
      await _dio.post('/torrent/add_file', data: formData);
    } on DioException catch (e) {
      throw SeedrException('Failed to add torrent file: ${e.message}');
    }
  }

  Future<void> deleteItem(String type, String id) async {
    _ensureAuth();
    try {
      await _dio.post('/$type/$id/delete');
    } on DioException catch (e) {
      throw SeedrException('Failed to delete: ${e.message}');
    }
  }

  void _ensureAuth() {
    if (_token == null) {
      throw SeedrException('Not authenticated. Please log in.');
    }
  }
}

class SeedrException implements Exception {
  final String message;
  SeedrException(this.message);

  @override
  String toString() => message;
}
