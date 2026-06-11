import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playlizt_app/providers/settings_provider.dart';
import 'package:playlizt_app/services/library_manager_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LibraryManager', () {
    test('scans configured folders into persistent library items', () async {
      SharedPreferences.setMockInitialValues({});
      final tempDir = await Directory.systemTemp.createTemp('playlizt-library-');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final mediaFile = File('${tempDir.path}/Episode 01.mp4');
      await mediaFile.writeAsBytes([1, 2, 3, 4]);

      final settings = SettingsProvider();
      await settings.ensureLoaded();
      await settings.setLibraryScanFolders([tempDir.path]);
      await settings.setRecursiveLibraryScan(true);

      final manager = LibraryManager(settingsProvider: settings);
      await Future<void>.delayed(Duration.zero);
      final result = await manager.rescan();

      expect(result.scannedFiles, 1);
      expect(result.importedItems, 1);
      expect(manager.items, hasLength(1));
      expect(manager.items.single.displayTitle, 'Episode 01');
      expect(manager.items.single.mediaType, LibraryMediaType.video);
    });

    test('round trips library item JSON with stable path IDs', () {
      final id = LibraryItem.stableIdForPath('/tmp/song.flac');
      final item = LibraryItem(
        id: id,
        path: '/tmp/song.flac',
        displayTitle: 'song',
        mediaType: LibraryItem.mediaTypeForPath('/tmp/song.flac'),
        source: LibraryItemSource.scanned,
        fileSizeBytes: 1024,
        dateAdded: DateTime.utc(2026, 6, 11),
        lastSeen: DateTime.utc(2026, 6, 11, 1),
      );

      final restored = LibraryItem.fromJson(item.toJson());

      expect(restored.id, id);
      expect(restored.mediaType, LibraryMediaType.audio);
      expect(restored.source, LibraryItemSource.scanned);
      expect(restored.fileSizeBytes, 1024);
    });
  });
}
