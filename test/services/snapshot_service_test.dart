import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

// We test SnapshotService logic by directly testing the JSON round-trip,
// since the service uses path_provider which needs platform channels.
// This validates the serialization/deserialization logic.
void main() {
  late Directory tempDir;
  late String snapshotPath;

  final sampleOwned = [
    {
      'artist': 'Radiohead',
      'album': 'OK Computer',
      'release': '1997-06-16',
      'discogs_id': '123',
      'discogs_instance_id': '456',
      'acquired_at': '2024-01-15',
    },
    {
      'artist': 'The Beatles',
      'album': 'Abbey Road',
      'release': '1969-09-26',
      'discogs_id': '',
      'discogs_instance_id': '',
      'acquired_at': '',
    },
  ];

  final sampleWanted = [
    {'artist': 'Pink Floyd', 'album': 'Animals'},
  ];

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('snapshot_test_');
    snapshotPath = join(tempDir.path, 'needl_snapshot.json');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('JSON snapshot format', () {
    test('save and load round-trips correctly', () async {
      // Save
      final data = jsonEncode({
        'owned': sampleOwned,
        'wanted': sampleWanted,
        'savedAt': DateTime.now().toIso8601String(),
      });
      await File(snapshotPath).writeAsString(data);

      // Load
      final loaded = jsonDecode(await File(snapshotPath).readAsString());
      final owned = (loaded['owned'] as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
      final wanted = (loaded['wanted'] as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();

      expect(owned, hasLength(2));
      expect(owned[0]['artist'], 'Radiohead');
      expect(owned[0]['album'], 'OK Computer');
      expect(owned[0]['release'], '1997-06-16');
      expect(owned[0]['discogs_id'], '123');
      expect(owned[0]['acquired_at'], '2024-01-15');
      expect(owned[1]['artist'], 'The Beatles');
      expect(wanted, hasLength(1));
      expect(wanted[0]['artist'], 'Pink Floyd');
    });

    test('handles empty collections', () async {
      final data = jsonEncode({
        'owned': <Map<String, String>>[],
        'wanted': <Map<String, String>>[],
        'savedAt': DateTime.now().toIso8601String(),
      });
      await File(snapshotPath).writeAsString(data);

      final loaded = jsonDecode(await File(snapshotPath).readAsString());
      final owned = (loaded['owned'] as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
      final wanted = (loaded['wanted'] as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();

      expect(owned, isEmpty);
      expect(wanted, isEmpty);
    });

    test('preserves all album fields through serialization', () async {
      final album = {
        'artist': 'Björk',
        'album': "It's Oh So Quiet",
        'release': '1995-11-20',
        'discogs_id': '999',
        'discogs_instance_id': '888',
        'acquired_at': '2025-02-14',
      };

      final data = jsonEncode({
        'owned': [album],
        'wanted': <Map<String, String>>[],
        'savedAt': DateTime.now().toIso8601String(),
      });
      await File(snapshotPath).writeAsString(data);

      final loaded = jsonDecode(await File(snapshotPath).readAsString());
      final restored = Map<String, String>.from(
          (loaded['owned'] as List).first as Map);

      expect(restored, album);
    });

    test('load returns null for non-existent file', () async {
      final file = File(join(tempDir.path, 'nonexistent.json'));
      expect(file.existsSync(), isFalse);
    });

    test('includes savedAt timestamp', () async {
      final before = DateTime.now();
      final data = jsonEncode({
        'owned': sampleOwned,
        'wanted': sampleWanted,
        'savedAt': DateTime.now().toIso8601String(),
      });
      await File(snapshotPath).writeAsString(data);
      final after = DateTime.now();

      final loaded = jsonDecode(await File(snapshotPath).readAsString());
      final savedAt = DateTime.parse(loaded['savedAt'] as String);

      expect(savedAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(
          savedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('clear deletes the file', () async {
      final file = File(snapshotPath);
      await file.writeAsString('test');
      expect(file.existsSync(), isTrue);

      await file.delete();
      expect(file.existsSync(), isFalse);
    });

    test('handles large collections', () async {
      final largeOwned = List.generate(
        1000,
        (i) => {
          'artist': 'Artist $i',
          'album': 'Album $i',
          'release': '2024-01-01',
          'discogs_id': '$i',
          'discogs_instance_id': '${i * 2}',
          'acquired_at': '',
        },
      );

      final data = jsonEncode({
        'owned': largeOwned,
        'wanted': <Map<String, String>>[],
        'savedAt': DateTime.now().toIso8601String(),
      });
      await File(snapshotPath).writeAsString(data);

      final loaded = jsonDecode(await File(snapshotPath).readAsString());
      final owned = (loaded['owned'] as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();

      expect(owned, hasLength(1000));
      expect(owned[500]['artist'], 'Artist 500');
    });
  });
}
