import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:vinyl_checker/config.dart';

class ApiUtils {
  static final _logger = Logger('ApiUtils');

  static Future<String> getSpotifyAccessToken() async {
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'client_credentials',
        'client_id': spotifyClientId,
        'client_secret': spotifyClientSecret,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      throw Exception('Failed to get Spotify token: ${response.statusCode}');
    }
  }

  static Future<String?> fetchCoverArt(String artist, String album) async {
    try {
      final token = await getSpotifyAccessToken();
      final query = Uri.encodeQueryComponent('artist:$artist album:$album');
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/search?q=$query&type=album'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['albums']['items'] as List<dynamic>;
        if (items.isNotEmpty) {
          final images = items[0]['images'] as List<dynamic>;
          if (images.isNotEmpty) {
            return images[0]['url'] as String;
          }
        }
      }
      return null;
    } catch (e) {
      _logger.warning('Error fetching cover art: $e');
      return null;
    }
  }
}
