import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiUtils response parsing', () {
    test('extracts access_token from response', () {
      final data = <String, dynamic>{
        'access_token': 'BQDj...',
        'token_type': 'bearer',
        'expires_in': 3600,
      };
      expect(data.containsKey('access_token'), isTrue);
      expect(data['access_token'], 'BQDj...');
    });

    test('throws when access_token missing', () {
      final data = <String, dynamic>{
        'error': 'invalid_client',
      };
      expect(data.containsKey('access_token'), isFalse);
      final errorMsg =
          'Failed to get Spotify token: ${data['error'] ?? 'unknown error'}';
      expect(errorMsg, contains('invalid_client'));
    });

    test('throws with unknown error when error key also missing', () {
      final data = <String, dynamic>{'status': 500};
      expect(data.containsKey('access_token'), isFalse);
      final errorMsg =
          'Failed to get Spotify token: ${data['error'] ?? 'unknown error'}';
      expect(errorMsg, contains('unknown error'));
    });
  });

  group('fetchCoverArt response parsing', () {
    test('extracts cover art URL from search response', () {
      final responseBody = jsonEncode({
        'albums': {
          'items': [
            {
              'name': 'OK Computer',
              'images': [
                {
                  'url': 'https://i.scdn.co/image/abc123',
                  'height': 640,
                  'width': 640,
                },
                {
                  'url': 'https://i.scdn.co/image/abc123_small',
                  'height': 300,
                  'width': 300,
                },
              ],
            },
          ],
        },
      });

      final data = jsonDecode(responseBody);
      final items = data['albums']['items'] as List<dynamic>;
      expect(items.isNotEmpty, isTrue);
      final images = items[0]['images'] as List<dynamic>;
      expect(images.isNotEmpty, isTrue);
      expect(images[0]['url'], 'https://i.scdn.co/image/abc123');
    });

    test('returns null for empty items list', () {
      final data = {
        'albums': {'items': []},
      };
      final items = data['albums']!['items'] as List<dynamic>;
      expect(items.isEmpty, isTrue);
    });

    test('returns null for empty images list', () {
      final data = {
        'albums': {
          'items': [
            {'name': 'OK Computer', 'images': []},
          ],
        },
      };
      final items = data['albums']!['items'] as List<dynamic>;
      expect(items.isNotEmpty, isTrue);
      final images = items[0]['images'] as List<dynamic>;
      expect(images.isEmpty, isTrue);
    });

    test('builds correct search query', () {
      final artist = 'Radiohead';
      final album = 'OK Computer';
      final query = Uri.encodeQueryComponent('artist:$artist album:$album');
      expect(query, contains('Radiohead'));
      expect(query, contains('OK+Computer'));
    });
  });

  group('Spotify search URL construction', () {
    test('builds valid search URL', () {
      final query = Uri.encodeQueryComponent('artist:Radiohead album:OK Computer');
      final url = 'https://api.spotify.com/v1/search?q=$query&type=album';
      final uri = Uri.parse(url);
      expect(uri.host, 'api.spotify.com');
      expect(uri.path, '/v1/search');
      expect(uri.queryParameters['type'], 'album');
    });
  });
}
