import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class SupabaseDataService {
  static final SupabaseDataService _instance = SupabaseDataService._internal();
  factory SupabaseDataService() => _instance;
  SupabaseDataService._internal();

  SupabaseClient get _client => Supabase.instance.client;
  String get _userId => AuthService().userId!;

  // --- Owned Albums ---

  Future<List<Map<String, String>>> getAllOwnedAlbums() async {
    final rows = await _client
        .from('owned_albums')
        .select()
        .eq('user_id', _userId)
        .order('artist');
    return rows.map<Map<String, String>>((row) => {
      'artist': row['artist'] as String,
      'album': row['album'] as String,
      'release': row['release_date'] as String? ?? '',
      'discogs_id': row['discogs_id']?.toString() ?? '',
      'discogs_instance_id': row['discogs_instance_id']?.toString() ?? '',
      'acquired_at': row['acquired_at'] as String? ?? '',
    }).toList();
  }

  Future<int> getOwnedCount() async {
    final result = await _client
        .from('owned_albums')
        .select()
        .eq('user_id', _userId)
        .count(CountOption.exact);
    return result.count;
  }

  Future<void> addOwnedAlbum({
    required String artist,
    required String album,
    required String releaseDate,
    String acquiredAt = '',
    int? discogsId,
    int? discogsInstanceId,
  }) async {
    await _client.from('owned_albums').insert({
      'user_id': _userId,
      'artist': artist,
      'album': album,
      'release_date': releaseDate,
      'acquired_at': acquiredAt,
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
    await _client
        .from('owned_albums')
        .update({
          'discogs_id': discogsId,
          'discogs_instance_id': discogsInstanceId,
        })
        .eq('user_id', _userId)
        .eq('artist', artist)
        .eq('album', album)
        .eq('release_date', releaseDate);
  }

  Future<void> deleteOwnedAlbum({
    required String artist,
    required String album,
    required String releaseDate,
  }) async {
    await _client
        .from('owned_albums')
        .delete()
        .eq('user_id', _userId)
        .eq('artist', artist)
        .eq('album', album)
        .eq('release_date', releaseDate);
  }

  // --- Wanted Albums ---

  Future<List<Map<String, String>>> getAllWantedAlbums() async {
    final rows = await _client
        .from('wanted_albums')
        .select()
        .eq('user_id', _userId)
        .order('artist');
    return rows.map<Map<String, String>>((row) => {
      'artist': row['artist'] as String,
      'album': row['album'] as String,
    }).toList();
  }

  Future<int> getWantedCount() async {
    final result = await _client
        .from('wanted_albums')
        .select()
        .eq('user_id', _userId)
        .count(CountOption.exact);
    return result.count;
  }

  Future<void> addWantedAlbum({
    required String artist,
    required String album,
  }) async {
    await _client.from('wanted_albums').insert({
      'user_id': _userId,
      'artist': artist,
      'album': album,
    });
  }

  Future<void> deleteWantedAlbum({
    required String artist,
    required String album,
  }) async {
    await _client
        .from('wanted_albums')
        .delete()
        .eq('user_id', _userId)
        .eq('artist', artist)
        .eq('album', album);
  }

  // --- Bulk Operations (for sync) ---

  Future<void> importOwnedAlbums(List<Map<String, String>> albums) async {
    if (albums.isEmpty) return;
    final rows = albums.map((a) => {
      'user_id': _userId,
      'artist': a['artist'] ?? '',
      'album': a['album'] ?? '',
      'release_date': a['release'] ?? '',
      'acquired_at': a['acquired_at'] ?? '',
    }).toList();
    // Upsert in batches of 500
    for (var i = 0; i < rows.length; i += 500) {
      final batch = rows.sublist(i, i + 500 > rows.length ? rows.length : i + 500);
      await _client.from('owned_albums').upsert(
        batch,
        onConflict: 'user_id, lower(artist), lower(album), release_date',
      );
    }
  }

  Future<void> importWantedAlbums(List<Map<String, String>> albums) async {
    if (albums.isEmpty) return;
    final rows = albums.map((a) => {
      'user_id': _userId,
      'artist': a['artist'] ?? '',
      'album': a['album'] ?? '',
    }).toList();
    for (var i = 0; i < rows.length; i += 500) {
      final batch = rows.sublist(i, i + 500 > rows.length ? rows.length : i + 500);
      await _client.from('wanted_albums').upsert(
        batch,
        onConflict: 'user_id, lower(artist), lower(album)',
      );
    }
  }
}
