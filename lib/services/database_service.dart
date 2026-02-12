import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  sqflite.Database? _db;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<sqflite.Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<sqflite.Database> _initDatabase() async {
    // Use FFI for desktop platforms
    if (!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      sqflite.databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'spin_tracker.db');

    return sqflite.openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE owned_albums (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            artist TEXT NOT NULL,
            album TEXT NOT NULL,
            release_date TEXT NOT NULL DEFAULT '',
            discogs_id INTEGER,
            discogs_instance_id INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE wanted_albums (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            artist TEXT NOT NULL,
            album TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_owned_artist ON owned_albums(artist)');
        await db.execute('CREATE INDEX idx_wanted_artist ON wanted_albums(artist)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE owned_albums ADD COLUMN discogs_id INTEGER');
          await db.execute('ALTER TABLE owned_albums ADD COLUMN discogs_instance_id INTEGER');
        }
      },
    );
  }

  Future<bool> hasData() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM owned_albums');
    return (result.first['count'] as int) > 0;
  }

  Future<List<Map<String, String>>> getAllOwnedAlbums() async {
    final db = await database;
    final rows = await db.query('owned_albums');
    return rows.map((row) => {
      'artist': row['artist'] as String,
      'album': row['album'] as String,
      'release': row['release_date'] as String,
      'discogs_id': row['discogs_id']?.toString() ?? '',
      'discogs_instance_id': row['discogs_instance_id']?.toString() ?? '',
    }).toList();
  }

  Future<List<Map<String, String>>> getAllWantedAlbums() async {
    final db = await database;
    final rows = await db.query('wanted_albums');
    return rows.map((row) => {
      'artist': row['artist'] as String,
      'album': row['album'] as String,
    }).toList();
  }

  Future<void> importOwnedAlbums(List<Map<String, String>> albums) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final album in albums) {
        await txn.insert('owned_albums', {
          'artist': album['artist'] ?? '',
          'album': album['album'] ?? '',
          'release_date': album['release'] ?? '',
        });
      }
    });
  }

  Future<void> importWantedAlbums(List<Map<String, String>> albums) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final album in albums) {
        await txn.insert('wanted_albums', {
          'artist': album['artist'] ?? '',
          'album': album['album'] ?? '',
        });
      }
    });
  }

  Future<void> addOwnedAlbum({
    required String artist,
    required String album,
    required String releaseDate,
    int? discogsId,
    int? discogsInstanceId,
  }) async {
    final db = await database;
    await db.insert('owned_albums', {
      'artist': artist,
      'album': album,
      'release_date': releaseDate,
      if (discogsId != null) 'discogs_id': discogsId,
      if (discogsInstanceId != null) 'discogs_instance_id': discogsInstanceId,
    });
  }

  Future<void> updateDiscogsId({
    required String artist,
    required String album,
    required String releaseDate,
    required int discogsId,
    required int discogsInstanceId,
  }) async {
    final db = await database;
    await db.update(
      'owned_albums',
      {'discogs_id': discogsId, 'discogs_instance_id': discogsInstanceId},
      where: 'artist = ? AND album = ? AND release_date = ?',
      whereArgs: [artist, album, releaseDate],
    );
  }

  Future<void> deleteOwnedAlbum({
    required String artist,
    required String album,
    required String releaseDate,
  }) async {
    final db = await database;
    await db.delete(
      'owned_albums',
      where: 'artist = ? AND album = ? AND release_date = ?',
      whereArgs: [artist, album, releaseDate],
    );
  }

  Future<void> deleteWantedAlbum({
    required String artist,
    required String album,
  }) async {
    final db = await database;
    await db.delete(
      'wanted_albums',
      where: 'artist = ? AND album = ?',
      whereArgs: [artist, album],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('owned_albums');
    await db.delete('wanted_albums');
  }
}
