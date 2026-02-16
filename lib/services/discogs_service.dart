import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';
import '../config.dart';

class DiscogsService {
  static final DiscogsService _instance = DiscogsService._internal();
  final _logger = Logger('DiscogsService');
  static const _timeout = Duration(seconds: 10);

  factory DiscogsService() => _instance;
  DiscogsService._internal();

  Map<String, String> get _headers => {
    'Authorization': 'Discogs token=$discogsPersonalAccessToken',
    'User-Agent': 'Needl/1.0',
  };

  Future<Map<String, dynamic>> getCollectionInfo() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.discogs.com/users/$discogsUsername/collection/folders/0',
            ),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get collection info: ${response.statusCode}');
      }
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
      final url =
          'https://api.discogs.com/users/$discogsUsername/collection/folders/0/releases?page=$page&per_page=$perPage&sort=$sort&sort_order=$sortOrder';

      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['releases']);
      } else {
        throw Exception('Failed to get collection releases: ${response.statusCode}');
      }
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
      final response = await http
          .get(
            Uri.parse('https://api.discogs.com/releases/$releaseId'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _logger.warning('Failed to get release details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.severe('Error getting release details: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _doSearch(
      Map<String, String> queryParams) async {
    final uri = Uri.https('api.discogs.com', '/database/search', queryParams);
    final response =
        await http.get(uri, headers: _headers).timeout(_timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['results'] ?? []);
    } else {
      _logger.warning('Search failed: ${response.statusCode}');
      throw Exception('Search failed: ${response.statusCode}');
    }
  }

  bool _isVinyl(Map<String, dynamic> result) {
    final formats = result['format'] as List? ?? [];
    return formats.any((f) =>
        f.toString().toLowerCase() == 'vinyl');
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
      final response = await http
          .post(
            Uri.parse(
              'https://api.discogs.com/users/$discogsUsername/collection/folders/1/releases/$releaseId',
            ),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final instanceId = data['instance_id'];
        if (instanceId is int) {
          _logger.info('Added release $releaseId to collection (instance: $instanceId)');
          return instanceId;
        }
        return -1;
      } else {
        _logger.warning('Failed to add to collection: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.severe('Error adding to collection: $e');
      return null;
    }
  }

  Future<bool> removeFromCollection(int releaseId, int instanceId) async {
    try {
      final response = await http
          .delete(
            Uri.parse(
              'https://api.discogs.com/users/$discogsUsername/collection/folders/1/releases/$releaseId/instances/$instanceId',
            ),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 204) {
        _logger.info('Removed release $releaseId instance $instanceId');
        return true;
      } else {
        _logger.warning('Failed to remove from collection: ${response.statusCode}');
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
