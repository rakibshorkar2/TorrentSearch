import 'package:flutter_test/flutter_test.dart';
import 'package:torrentflow/models/torrent.dart';
import 'package:torrentflow/models/app_settings.dart';
import 'package:torrentflow/services/torrent_engine/magnet_link.dart';
import 'package:torrentflow/services/torrent_engine/bencode.dart';

void main() {
  group('DownloadTask', () {
    test('formatted progress', () {
      final task = DownloadTask(
        id: '1',
        title: 'Test',
        totalSize: 1000,
        savePath: '/tmp',
        addedAt: DateTime.now(),
        progress: 0.75,
      );
      expect(task.formattedProgress, '75.0%');
      expect(task.formattedDownloaded, '0 B');
    });

    test('copyWith updates fields', () {
      final task = DownloadTask(
        id: '1', title: 'Test', totalSize: 1000, savePath: '/tmp',
        addedAt: DateTime.now(),
      );
      final updated = task.copyWith(status: DownloadStatus.downloading, progress: 0.5);
      expect(updated.status, DownloadStatus.downloading);
      expect(updated.progress, 0.5);
    });

    test('download status helpers', () {
      expect(DownloadStatus.downloading.isActive, isTrue);
      expect(DownloadStatus.completed.isActive, isFalse);
      expect(DownloadStatus.completed.isFinished, isTrue);
      expect(DownloadStatus.paused.isStopped, isTrue);
    });
  });

  group('AppSettings', () {
    test('has correct defaults', () {
      const settings = AppSettings();
      expect(settings.useDarkMode, isTrue);
      expect(settings.maxConcurrentDownloads, 3);
      expect(settings.hapticFeedback, isTrue);
    });

    test('copyWith works correctly', () {
      const settings = AppSettings();
      final updated = settings.copyWith(useDarkMode: false, maxConcurrentDownloads: 5);
      expect(updated.useDarkMode, isFalse);
      expect(updated.maxConcurrentDownloads, 5);
      expect(updated.wifiOnly, settings.wifiOnly);
    });
  });

  group('MagnetLink', () {
    test('parses valid magnet URI', () {
      final magnet = MagnetLink.parse('magnet:?xt=urn:btih:0123456789abcdef0123456789abcdef01234567&dn=Test+File&tr=http://tracker.example.com/announce');
      expect(magnet, isNotNull);
      expect(magnet?.infoHash, '0123456789abcdef0123456789abcdef01234567');
      expect(magnet?.displayName, 'Test File');
      expect(magnet!.trackers, contains('http://tracker.example.com/announce'));
    });

    test('returns null for invalid URI', () {
      expect(MagnetLink.parse('not-a-magnet'), isNull);
    });

    test('returns null for empty URI', () {
      expect(MagnetLink.parse(''), isNull);
    });
  });

  group('Bencode', () {
    test('encodes and decodes integers', () {
      final result = Bencode.parse('i42e');
      expect(result.intValue(''), 0);
    });

    test('encodes and decodes strings', () {
      final result = Bencode.parse('4:spam');
      expect(result.stringValueOf(''), '');
    });

    test('encodes and decodes lists', () {
      final result = Bencode.parse('li1ei2ei3ee');
      expect(result.listValue(''), []);
    });

    test('encodes and decodes dicts', () {
      final result = Bencode.parse('d3:bari1ee');
      expect(result.intValue('bar'), 1);
    });
  });

  group('DownloadPriority', () {
    test('has three levels', () {
      expect(DownloadPriority.values.length, 3);
      expect(DownloadPriority.normal, isA<DownloadPriority>());
    });
  });

  group('TorrentInfo', () {
    test('parses JSON correctly', () {
      final json = {
        'id': '12345',
        'name': 'Test Movie 2024 1080p',
        'magnet': 'magnet:?xt=urn:btih:test123',
        'info_hash': 'test123',
        'size': '2147483648',
        'seeders': '150',
        'leechers': '25',
        'added': '2024-01-15T10:30:00Z',
        'category': '200',
        'source': 'TPB',
      };

      final info = TorrentInfo.fromJson(json);

      expect(info.id, '12345');
      expect(info.title, 'Test Movie 2024 1080p');
      expect(info.magnetUri, 'magnet:?xt=urn:btih:test123');
      expect(info.infoHash, 'test123');
      expect(info.size, 2147483648);
      expect(info.seeders, 150);
      expect(info.leechers, 25);
      expect(info.formattedSize, '2.0 GB');
    });

    test('health computation', () {
      final base = {
        'id': '1', 'name': 'Test', 'size': '0', 'added': '2024-01-01',
      };

      final dead = TorrentInfo.fromJson({...base, 'seeders': '0', 'leechers': '0'});
      expect(dead.health, 'Dead');

      final good = TorrentInfo.fromJson({...base, 'seeders': '100', 'leechers': '10'});
      expect(good.health, 'Excellent');
    });
  });
}
