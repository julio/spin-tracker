import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'discogs_auth_service.dart';

class DiscogsService {
  static final DiscogsService _instance = DiscogsService._internal();
  final _logger = Logger('DiscogsService');

  factory DiscogsService() => _instance;
  DiscogsService._internal();

  String? _cachedUsername;

  Future<String> _getUsername() async {
    _cachedUsername ??= await DiscogsAuthService().getConnectedUsername();
    if (_cachedUsername == null || _cachedUsername!.isEmpty) {
      throw Exception('Discogs account not connected');
    }
    return _cachedUsername!;
  }

  /// Clears cached username (call when user disconnects).
  void clearUsernameCache() {
    _cachedUsername = null;
  }

  Future<Map<String, dynamic>> _proxyRequest(
    String method,
    String path, [
    String? query,
  ]) async {
    final response = await Supabase.instance.client.functions.invoke(
      'discogs-api',
      body: {
        'method': method,
        'path': path,
        if (query != null) 'query': query,
      },
    );

    if (response.status != 200) {
      final error = response.data is Map
          ? response.data['error'] ?? 'Request failed'
          : 'Request failed with status ${response.status}';
      throw Exception(error);
    }

    final data = response.data;
    if (data is String) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCollectionInfo() async {
    try {
      final username = await _getUsername();
      return await _proxyRequest(
        'GET',
        '/users/$username/collection/folders/0',
      );
    } catch (e) {
      _logger.severe('Error getting collection info: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCollectionReleases({
    int page = 1,
    int perPage = 50,
    String sort = 'added',
    String sortOrder = 'desc',
  }) async {
    try {
      final username = await _getUsername();
      final data = await _proxyRequest(
        'GET',
        '/users/$username/collection/folders/0/releases',
        'page=$page&per_page=$perPage&sort=$sort&sort_order=$sortOrder',
      );
      return List<Map<String, dynamic>>.from(data['releases']);
    } catch (e) {
      _logger.severe('Error getting collection releases: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllCollectionReleases() async {
    final allReleases = <Map<String, dynamic>>[];
    int page = 1;
    while (true) {
      final releases = await getCollectionReleases(
        page: page,
        perPage: 100,
        sort: 'artist',
        sortOrder: 'asc',
      );
      allReleases.addAll(releases);
      if (releases.length < 100) break;
      page++;
    }
    return allReleases;
  }

  Future<Map<String, dynamic>?> getReleaseDetails(int releaseId) async {
    try {
      return await _proxyRequest('GET', '/releases/$releaseId');
    } catch (e) {
      _logger.severe('Error getting release details: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _doSearch(
      Map<String, String> queryParams) async {
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final data = await _proxyRequest('GET', '/database/search', queryString);
    return List<Map<String, dynamic>>.from(data['results'] ?? []);
  }

  bool _isVinyl(Map<String, dynamic> result) {
    final formats = result['format'] as List? ?? [];
    return formats.any((f) => f.toString().toLowerCase() == 'vinyl');
  }

  Future<List<Map<String, dynamic>>> searchReleases({
    required String artist,
    required String title,
  }) async {
    try {
      // 1) Exact match, vinyl only
      var results = await _doSearch({
        'artist': artist,
        'release_title': title,
        'type': 'release',
        'format': 'Vinyl',
        'per_page': '20',
      });
      if (results.isNotEmpty) return results;

      // 2) Fuzzy search, vinyl only
      results = await _doSearch({
        'artist': artist,
        'q': title,
        'type': 'release',
        'format': 'Vinyl',
        'per_page': '20',
      });
      if (results.isNotEmpty) return results;

      // 3) Fuzzy search, all formats — sort vinyl to top
      results = await _doSearch({
        'artist': artist,
        'q': title,
        'type': 'release',
        'per_page': '20',
      });
      results.sort((a, b) {
        final aVinyl = _isVinyl(a) ? 0 : 1;
        final bVinyl = _isVinyl(b) ? 0 : 1;
        return aVinyl.compareTo(bVinyl);
      });
      return results;
    } catch (e) {
      _logger.severe('Error searching releases: $e');
      rethrow;
    }
  }

  Future<int?> addToCollection(int releaseId) async {
    try {
      final username = await _getUsername();
      final response = await Supabase.instance.client.functions.invoke(
        'discogs-api',
        body: {
          'method': 'POST',
          'path': '/users/$username/collection/folders/1/releases/$releaseId',
        },
      );

      if (response.status == 201 || response.status == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        final instanceId = data['instance_id'];
        if (instanceId is int) {
          _logger.info('Added release $releaseId to collection (instance: $instanceId)');
          return instanceId;
        }
        return -1;
      } else {
        _logger.warning('Failed to add to collection: ${response.status}');
        return null;
      }
    } catch (e) {
      _logger.severe('Error adding to collection: $e');
      return null;
    }
  }

  Future<bool> removeFromCollection(int releaseId, int instanceId) async {
    try {
      final username = await _getUsername();
      final response = await Supabase.instance.client.functions.invoke(
        'discogs-api',
        body: {
          'method': 'DELETE',
          'path': '/users/$username/collection/folders/1/releases/$releaseId/instances/$instanceId',
        },
      );

      if (response.status == 204 || response.status == 200) {
        _logger.info('Removed release $releaseId instance $instanceId');
        return true;
      } else {
        _logger.warning('Failed to remove from collection: ${response.status}');
        return false;
      }
    } catch (e) {
      _logger.severe('Error removing from collection: $e');
      return false;
    }
  }

  Future<void> loadReleaseThumbnail(Map<String, dynamic> release) async {
    try {
      final basicInfo = release['basic_information'] as Map<String, dynamic>;

      if (basicInfo['thumb'] != null &&
          basicInfo['thumb'].toString().isNotEmpty) {
        return;
      }

      final details = await getReleaseDetails(basicInfo['id'] as int);
      if (details != null && details['images'] != null) {
        final images = details['images'] as List;
        if (images.isNotEmpty) {
          basicInfo['thumb'] = images.first['uri150'] ?? '';
        }
      }
    } catch (e) {
      _logger.warning('Error loading thumbnail for release: $e');
    }
  }
}
