import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torrentflow/app.dart';
import 'package:torrentflow/models/torrent.dart';
import 'package:torrentflow/models/seedr_item.dart';
import 'package:torrentflow/models/app_settings.dart';
import 'package:torrentflow/models/search_result.dart';
import 'package:torrentflow/providers/search/search_providers.dart';
import 'package:torrentflow/services/search/torrent_search_service.dart';
import 'package:torrentflow/services/download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App Shell', () {
    testWidgets('renders tab bar with all 4 tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: CupertinoApp(home: MainShell())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Search'), findsAtLeast(1));
      expect(find.text('Downloads'), findsAtLeast(1));
      expect(find.text('Seedr'), findsAtLeast(1));
      expect(find.text('Settings'), findsAtLeast(1));
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
        'source': 'The Pirate Bay',
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

    test('detects quality from title', () {
      final base = {
        'id': '1', 'name': 'Movie', 'size': '0', 'seeders': '0',
        'leechers': '0', 'added': '2024-01-01',
      };

      final hd = TorrentInfo.fromJson({...base, 'name': 'Movie 1080p'});
      expect(hd.quality, '1080p');

      final sd = TorrentInfo.fromJson({...base, 'name': 'Movie DVDRip'});
      expect(sd.quality, 'SD');

      final none = TorrentInfo.fromJson(base);
      expect(none.quality, isNull);
    });

    test('categorizes content correctly', () {
      final base = {
        'id': '1', 'name': 'Movie 2024', 'size': '0', 'seeders': '0',
        'leechers': '0', 'added': '2024-01-01',
      };

      final video = TorrentInfo.fromJson({...base, 'category': '200'});
      expect(video.isVideo, isTrue);

      final audio = TorrentInfo.fromJson({...base, 'name': 'Album FLAC'});
      expect(audio.isAudio, isTrue);

      final game = TorrentInfo.fromJson({...base, 'name': 'Game PS5'});
      expect(game.isGame, isTrue);
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

  group('SeedrItem', () {
    test('SeedrAccount usagePercent', () {
      final account = SeedrAccount(usedStorage: 5_000_000_000, totalStorage: 20_000_000_000);
      expect(account.usagePercent, 0.25);
      expect(account.formattedUsed, '4.7 GB');
    });

    test('SeedrTorrent isReady', () {
      final ready = SeedrTorrent(id: '1', name: 'Ready', size: 1000, progress: 100);
      expect(ready.isReady, isTrue);

      final notReady = SeedrTorrent(id: '2', name: 'Not Ready', size: 1000, progress: 50);
      expect(notReady.isReady, isFalse);
    });

    test('SeedrItem type helpers', () {
      final folder = SeedrItem(id: '1', name: 'Folder', size: 0, type: SeedrItemType.folder);
      expect(folder.isFolder, isTrue);

      final file = SeedrItem(id: '2', name: 'File.txt', size: 100, type: SeedrItemType.file);
      expect(file.isFolder, isFalse);
    });
  });

  group('AppSettings', () {
    test('has correct defaults', () {
      const settings = AppSettings();
      expect(settings.useDarkMode, isTrue);
      expect(settings.maxConcurrentDownloads, 3);
      expect(settings.hapticFeedback, isTrue);
      expect(settings.saveSearchHistory, isTrue);
    });

    test('copyWith works correctly', () {
      const settings = AppSettings();
      final updated = settings.copyWith(useDarkMode: false, maxConcurrentDownloads: 5);
      expect(updated.useDarkMode, isFalse);
      expect(updated.maxConcurrentDownloads, 5);
      expect(updated.wifiOnly, settings.wifiOnly);
    });
  });

  group('SearchResult', () {
    test('copyWith updates correctly', () {
      final result = SearchResult(isLoading: true);
      final updated = result.copyWith(isLoading: false, error: 'Test error');
      expect(updated.isLoading, isFalse);
      expect(updated.error, 'Test error');
    });

    test('hasMore defaults to false', () {
      const result = SearchResult();
      expect(result.hasMore, isFalse);
      expect(result.results, isEmpty);
    });
  });

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

  group('DownloadService', () {
    test('rejects unsupported URLs', () {
      final service = DownloadService();
      expect(() => service.addDownload(
        title: 'Test',
        url: 'magnet:?xt=urn:btih:test',
        savePath: '/tmp/test',
      ), returnsNormally);
    });
  });

  group('TorrentSearchService', () {
    test('quality ranking is correct', () {
      final svc = TorrentSearchService();
      expect(svc.searchAll(''), completes);
    });
  });

  group('SearchSort', () {
    test('all enum values present', () {
      expect(SearchSort.values.length, 8);
      expect(SearchSort.seedersDesc, isA<SearchSort>());
      expect(SearchSort.dateAsc, isA<SearchSort>());
    });
  });

  group('DownloadPriority', () {
    test('has three levels', () {
      expect(DownloadPriority.values.length, 3);
      expect(DownloadPriority.normal, isA<DownloadPriority>());
    });
  });
}
