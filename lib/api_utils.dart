import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiUtils {
  static final _logger = Logger('ApiUtils');

  static Future<String> getSpotifyAccessToken() async {
    final response = await Supabase.instance.client.functions.invoke(
      'spotify-token',
      method: HttpMethod.post,
    );

    final data = response.data as Map<String, dynamic>;
    if (data.containsKey('access_token')) {
      return data['access_token'] as String;
    } else {
      throw Exception('Failed to get Spotify token: ${data['error'] ?? 'unknown error'}');
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
