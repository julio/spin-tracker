import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';
import '../config.dart';

class DiscogsService {
  static final DiscogsService _instance = DiscogsService._internal();
  final _logger = Logger('DiscogsService');
  static const _timeout = Duration(seconds: 10);

  factory DiscogsService() {
    print('DEBUG: DiscogsService factory called'); // Immediate print
    return _instance;
  }

  DiscogsService._internal() {
    print('DEBUG: DiscogsService._internal called'); // Immediate print
  }

  Map<String, String> get _headers => {
    'Authorization': 'Discogs token $discogsPersonalAccessToken',
    'User-Agent': 'VinylChecker/1.0',
  };

  Future<Map<String, dynamic>> getCollectionInfo() async {
    try {
      _logger.info('Starting collection info request...');
      print(
        'DEBUG: About to make collection info request',
      ); // Direct console output

      final response = await http
          .get(
            Uri.parse(
              'https://api.discogs.com/users/$discogsUsername/collection/folders/0',
            ),
            headers: _headers,
          )
          .timeout(_timeout);

      print(
        'DEBUG: Got collection info response: ${response.statusCode}',
      ); // Direct console output
      _logger.info('Collection info response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.info('Collection count: ${data['count']}');
        return data;
      } else {
        final error =
            'Failed to get collection info: ${response.statusCode}\nResponse: ${response.body}\nHeaders: ${response.headers}';
        print('DEBUG: Error - $error'); // Direct console output
        _logger.warning(error);
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      final error = 'Error getting collection info: $e';
      print('DEBUG: Exception - $error'); // Direct console output
      _logger.severe('$error\n$stackTrace');
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
      _logger.info('Starting collection releases request...');
      print(
        'DEBUG: About to make collection releases request',
      ); // Direct console output

      final url =
          'https://api.discogs.com/users/$discogsUsername/collection/folders/0/releases?page=$page&per_page=$perPage&sort=$sort&sort_order=$sortOrder';
      _logger.info('URL: $url');
      print('DEBUG: URL - $url'); // Direct console output

      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      print(
        'DEBUG: Got collection releases response: ${response.statusCode}',
      ); // Direct console output
      _logger.info(
        'Collection releases response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final releases = List<Map<String, dynamic>>.from(data['releases']);
        _logger.info('Fetched ${releases.length} releases');
        return releases;
      } else {
        final error =
            'Failed to get collection releases: ${response.statusCode}\nResponse: ${response.body}\nHeaders: ${response.headers}';
        print('DEBUG: Error - $error'); // Direct console output
        _logger.warning(error);
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      final error = 'Error getting collection releases: $e';
      print('DEBUG: Exception - $error'); // Direct console output
      _logger.severe('$error\n$stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getReleaseDetails(int releaseId) async {
    try {
      _logger.info('Starting release details request for ID: $releaseId');
      print(
        'DEBUG: About to make release details request for ID: $releaseId',
      ); // Direct console output

      final response = await http
          .get(
            Uri.parse('https://api.discogs.com/releases/$releaseId'),
            headers: _headers,
          )
          .timeout(_timeout);

      print(
        'DEBUG: Got release details response: ${response.statusCode}',
      ); // Direct console output
      _logger.info('Release details response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error =
            'Failed to get release details: ${response.statusCode}\nResponse: ${response.body}';
        print('DEBUG: Error - $error'); // Direct console output
        _logger.warning(error);
        return null;
      }
    } catch (e, stackTrace) {
      final error = 'Error getting release details: $e';
      print('DEBUG: Exception - $error'); // Direct console output
      _logger.severe('$error\n$stackTrace');
      return null;
    }
  }

  Future<void> loadReleaseThumbnail(Map<String, dynamic> release) async {
    try {
      final basicInfo = release['basic_information'] as Map<String, dynamic>;

      // Check if we already have a thumbnail
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
      final error = 'Error loading thumbnail for release: $e';
      print('DEBUG: Exception - $error'); // Direct console output
      _logger.warning(error);
    }
  }
}
