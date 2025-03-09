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
}
