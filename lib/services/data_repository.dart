import 'package:logging/logging.dart';
import 'supabase_data_service.dart';
import 'snapshot_service.dart';
import 'auth_service.dart';

/// Coordinates Supabase (primary) with in-memory cache and JSON offline snapshot.
/// Reads from in-memory cache. Writes to Supabase, then refreshes cache.
/// Enforces freemium tier limits.
class DataRepository {
  static final DataRepository _instance = DataRepository._internal();
  factory DataRepository() => _instance;
  DataRepository._internal();

  final _logger = Logger('DataRepository');
  final _remote = SupabaseDataService();
  final _snapshot = SnapshotService();
  final _auth = AuthService();

  String? _cachedTier;

  // --- In-memory cache ---
  List<Map<String, String>> _ownedAlbums = [];
  List<Map<String, String>> _wantedAlbums = [];
  bool _isLoaded = false;
  bool _isOffline = false;

  bool get isOffline => _isOffline;
  bool get isLoaded => _isLoaded;

  // --- Tier ---

  Future<String> get tier async {
    _cachedTier ??= await _auth.getTier();
    return _cachedTier!;
  }

  void clearTierCache() => _cachedTier = null;

  bool _isPremium(String tier) => tier == 'premium';

  static const int freeOwnedLimit = 100;
  static const int freeWantedLimit = 50;

  // --- Read (from in-memory cache) ---

  Future<List<Map<String, String>>> getAllOwnedAlbums() async => _ownedAlbums;

  Future<List<Map<String, String>>> getAllWantedAlbums() async => _wantedAlbums;

  Future<int> getOwnedCount() async => _ownedAlbums.length;
  Future<int> getWantedCount() async => _wantedAlbums.length;

  // --- Initial Load ---

  /// Called on app start. Tries Supabase first; falls back to snapshot.
  Future<void> loadData() async {
    try {
      await _fetchFromRemote();
      _isOffline = false;
      // Clean up old SQLite database if it exists
      _snapshot.deleteOldDatabase();
    } catch (e) {
      _logger.warning('Supabase unreachable, falling back to snapshot: $e');
      final snapshot = await _snapshot.load();
      if (snapshot != null) {
        _ownedAlbums = snapshot.owned;
        _wantedAlbums = snapshot.wanted;
        _isLoaded = true;
        _isOffline = true;
      } else {
        _logger.severe('No snapshot available and Supabase is unreachable');
        _isLoaded = false;
        _isOffline = true;
      }
    }
  }

  /// Fetches from Supabase, updates in-memory cache and snapshot.
  Future<void> _fetchFromRemote() async {
    _logger.info('Fetching data from Supabase...');
    final owned = await _remote.getAllOwnedAlbums();
    final wanted = await _remote.getAllWantedAlbums();
    _ownedAlbums = owned;
    _wantedAlbums = wanted;
    _isLoaded = true;
    _logger.info('Loaded: ${owned.length} owned, ${wanted.length} wanted');
    // Persist snapshot in background (fire-and-forget)
    _snapshot.save(owned: owned, wanted: wanted);
  }

  // --- Write (Supabase only, then refresh cache) ---

  Future<void> addOwnedAlbum({
    required String artist,
    required String album,
    required String releaseDate,
    String acquiredAt = '',
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
      acquiredAt: acquiredAt,
      discogsId: discogsId,
      discogsInstanceId: discogsInstanceId,
    );
    await _fetchFromRemote();
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
    await _fetchFromRemote();
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
    await _fetchFromRemote();
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
    await _fetchFromRemote();
  }

  Future<void> deleteWantedAlbum({
    required String artist,
    required String album,
  }) async {
    await _remote.deleteWantedAlbum(artist: artist, album: album);
    await _fetchFromRemote();
  }

  // --- Sync (refresh from Supabase) ---

  Future<void> syncFromRemote() async {
    await _fetchFromRemote();
    _isOffline = false;
  }

  // --- Remote counts (for sync status) ---

  Future<int> getRemoteOwnedCount() => _remote.getOwnedCount();
  Future<int> getRemoteWantedCount() => _remote.getWantedCount();

  Future<List<Map<String, String>>> getRemoteOwnedAlbums() =>
      _remote.getAllOwnedAlbums();

  Future<List<Map<String, String>>> getRemoteWantedAlbums() =>
      _remote.getAllWantedAlbums();

  /// Clears in-memory cache and snapshot (call on sign-out).
  void clearAll() {
    _ownedAlbums = [];
    _wantedAlbums = [];
    _isLoaded = false;
    _isOffline = false;
    _cachedTier = null;
    _snapshot.clear();
  }
}
