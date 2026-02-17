import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';

/// Read-only offline snapshot stored as a JSON file.
/// Written after each successful Supabase fetch. Never modified by writes.
class SnapshotService {
  static final SnapshotService _instance = SnapshotService._internal();
  factory SnapshotService() => _instance;
  SnapshotService._internal();

  final _logger = Logger('SnapshotService');

  Future<String> get _filePath async {
    final dir = await getApplicationDocumentsDirectory();
    return join(dir.path, 'needl_snapshot.json');
  }

  /// Persists the current album lists to disk.
  Future<void> save({
    required List<Map<String, String>> owned,
    required List<Map<String, String>> wanted,
  }) async {
    try {
      final path = await _filePath;
      final data = jsonEncode({
        'owned': owned,
        'wanted': wanted,
        'savedAt': DateTime.now().toIso8601String(),
      });
      await File(path).writeAsString(data);
      _logger.info(
          'Snapshot saved: ${owned.length} owned, ${wanted.length} wanted');
    } catch (e) {
      _logger.warning('Failed to save snapshot: $e');
    }
  }

  /// Loads the last-saved snapshot, or null if none exists.
  Future<({List<Map<String, String>> owned, List<Map<String, String>> wanted})?>
      load() async {
    try {
      final path = await _filePath;
      final file = File(path);
      if (!await file.exists()) return null;
      final data = jsonDecode(await file.readAsString());
      final owned = (data['owned'] as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
      final wanted = (data['wanted'] as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
      _logger.info(
          'Snapshot loaded: ${owned.length} owned, ${wanted.length} wanted');
      return (owned: owned, wanted: wanted);
    } catch (e) {
      _logger.warning('Failed to load snapshot: $e');
      return null;
    }
  }

  /// Deletes the snapshot file (e.g., on sign-out).
  Future<void> clear() async {
    try {
      final path = await _filePath;
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      _logger.warning('Failed to clear snapshot: $e');
    }
  }

  /// Deletes the old SQLite database file if it exists (one-time migration).
  Future<void> deleteOldDatabase() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File(join(dir.path, 'spin_tracker.db'));
      if (await dbFile.exists()) {
        await dbFile.delete();
        _logger.info('Deleted old SQLite database');
      }
    } catch (e) {
      _logger.warning('Failed to delete old database: $e');
    }
  }
}
