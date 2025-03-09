import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';
import '../config.dart';

class DiscogsService {
  static final DiscogsService _instance = DiscogsService._internal();
  final _logger = Logger('DiscogsService');

  factory DiscogsService() {
    return _instance;
  }

  DiscogsService._internal();

  Map<String, String> get _headers => {
    'Authorization': 'Discogs token $discogsPersonalAccessToken',
    'User-Agent': 'VinylChecker/1.0',
  };

  Future<Map<String, dynamic>> getCollectionInfo() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.discogs.com/users/$discogsUsername/collection/folders/0',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _logger.warning(
          'Failed to get collection info: ${response.statusCode}',
        );
        throw Exception('Failed to get collection info');
      }
    } catch (e) {
      _logger.severe('Error getting collection info: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getReleaseDetails(int releaseId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.discogs.com/releases/$releaseId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.info('Release details images: ${data['images']}');
        return data;
      } else {
        _logger.warning(
          'Failed to get release details: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      _logger.severe('Error getting release details: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCollectionReleases({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.discogs.com/users/$discogsUsername/collection/folders/0/releases?page=$page&per_page=$perPage',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final releases = List<Map<String, dynamic>>.from(data['releases']);

        // Get detailed information for each release
        for (var release in releases) {
          final basicInfo =
              release['basic_information'] as Map<String, dynamic>;
          final details = await getReleaseDetails(basicInfo['id'] as int);
          if (details != null && details['images'] != null) {
            final images = details['images'] as List;
            if (images.isNotEmpty) {
              basicInfo['thumb'] = images.first['uri150'] ?? '';
            }
          }
        }

        return releases;
      } else {
        _logger.warning(
          'Failed to get collection releases: ${response.statusCode}\nResponse: ${response.body}',
        );
        throw Exception('Failed to get collection releases');
      }
    } catch (e) {
      _logger.severe('Error getting collection releases: $e');
      rethrow;
    }
  }
}
