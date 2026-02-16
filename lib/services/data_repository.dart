import 'package:logging/logging.dart';
import 'database_service.dart';
import 'supabase_data_service.dart';
import 'auth_service.dart';

/// Coordinates Supabase (remote) and SQLite (local cache).
/// Reads from local cache, writes to Supabase first then updates cache.
/// Enforces freemium tier limits.
class DataRepository {
  static final DataRepository _instance = DataRepository._internal();
  factory DataRepository() => _instance;
  DataRepository._internal();

  final _logger = Logger('DataRepository');
  final _remote = SupabaseDataService();
  final _local = DatabaseService();
  final _auth = AuthService();

  String? _cachedTier;

  // --- Tier ---

  Future<String> get tier async {
    _cachedTier ??= await _auth.getTier();
    return _cachedTier!;
  }

  void clearTierCache() => _cachedTier = null;

  bool _isPremium(String tier) => tier == 'premium';

  static const int freeOwnedLimit = 100;
  static const int freeWantedLimit = 50;

  // --- Read (from local cache) ---

  Future<bool> hasData() => _local.hasData();

  Future<List<Map<String, String>>> getAllOwnedAlbums() =>
      _local.getAllOwnedAlbums();

  Future<List<Map<String, String>>> getAllWantedAlbums() =>
      _local.getAllWantedAlbums();

  Future<int> getOwnedCount() => _local.getOwnedCount();
  Future<int> getWantedCount() => _local.getWantedCount();

  // --- Write (Supabase first, then local) ---

  Future<void> addOwnedAlbum({
    required String artist,
    required String album,
    required String releaseDate,
    int? discogsId,
    int? discogsInstanceId,
  }) async {
    final currentTier = await tier;
    if (!_isPremium(currentTier)) {
      final count = await _remote.getOwnedCount();
      if (count >= freeOwnedLimit) {
        throw Exception(
          'Free tier limit reached ($freeOwnedLimit owned albums). Upgrade to Premium for unlimited albums.',
        );
      }
    }

    await _remote.addOwnedAlbum(
      artist: artist,
      album: album,
      releaseDate: releaseDate,
      discogsId: discogsId,
      discogsInstanceId: discogsInstanceId,
    );
    await _local.addOwnedAlbum(
      artist: artist,
      album: album,
      releaseDate: releaseDate,
      discogsId: discogsId,
      discogsInstanceId: discogsInstanceId,
    );
  }

  Future<void> addWantedAlbum({
    required String artist,
    required String album,
  }) async {
    final currentTier = await tier;
    if (!_isPremium(currentTier)) {
      final count = await _remote.getWantedCount();
      if (count >= freeWantedLimit) {
        throw Exception(
          'Free tier limit reached ($freeWantedLimit wanted albums). Upgrade to Premium for unlimited albums.',
        );
      }
    }

    await _remote.addWantedAlbum(artist: artist, album: album);
    await _local.importWantedAlbums([{'artist': artist, 'album': album}]);
  }

  Future<void> updateDiscogsId({
    required String artist,
    required String album,
    required String releaseDate,
    required int discogsId,
    required int discogsInstanceId,
  }) async {
    await _remote.updateDiscogsId(
      artist: artist,
      album: album,
      releaseDate: releaseDate,
      discogsId: discogsId,
      discogsInstanceId: discogsInstanceId,
    );
    await _local.updateDiscogsId(
      artist: artist,
      album: album,
      releaseDate: releaseDate,
      discogsId: discogsId,
      discogsInstanceId: discogsInstanceId,
    );
  }

  Future<void> deleteOwnedAlbum({
    required String artist,
    required String album,
    required String releaseDate,
  }) async {
    await _remote.deleteOwnedAlbum(
      artist: artist,
      album: album,
      releaseDate: releaseDate,
    );
    await _local.deleteOwnedAlbum(
      artist: artist,
      album: album,
      releaseDate: releaseDate,
    );
  }

  Future<void> deleteWantedAlbum({
    required String artist,
    required String album,
  }) async {
    await _remote.deleteWantedAlbum(artist: artist, album: album);
    await _local.deleteWantedAlbum(artist: artist, album: album);
  }

  // --- Sync: pull from Supabase, replace local cache ---

  Future<void> syncFromRemote() async {
    _logger.info('Starting sync from Supabase...');
    final owned = await _remote.getAllOwnedAlbums();
    final wanted = await _remote.getAllWantedAlbums();

    await _local.clearAll();
    await _local.importOwnedAlbums(owned);
    await _local.importWantedAlbums(wanted);
    _logger.info('Sync complete: ${owned.length} owned, ${wanted.length} wanted');
  }

  // --- Remote counts (for sync status) ---

  Future<int> getRemoteOwnedCount() => _remote.getOwnedCount();
  Future<int> getRemoteWantedCount() => _remote.getWantedCount();

  Future<List<Map<String, String>>> getRemoteOwnedAlbums() =>
      _remote.getAllOwnedAlbums();

  Future<List<Map<String, String>>> getRemoteWantedAlbums() =>
      _remote.getAllWantedAlbums();
}
