import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify/spotify.dart';
import 'package:logging/logging.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SpotifyService {
  static final SpotifyService _instance = SpotifyService._internal();
  late final SpotifyApi _spotifyApi;
  bool _isConnected = false;
  final _logger = Logger('SpotifyService');

  factory SpotifyService() {
    return _instance;
  }

  SpotifyService._internal() {
    _spotifyApi = SpotifyApi(
      SpotifyApiCredentials(spotifyClientId, spotifyClientSecret),
    );
  }

  Future<bool> connect() async {
    try {
      _isConnected = await SpotifySdk.connectToSpotifyRemote(
        clientId: spotifyClientId,
        redirectUrl: spotifyRedirectUri,
      );
      return _isConnected;
    } catch (e) {
      _logger.warning('Failed to connect to Spotify: $e');
      return false;
    }
  }

  Future<void> playAlbum(String artist, String album) async {
    if (!_isConnected) {
      await connect();
    }

    try {
      final token = await _spotifyApi.getCredentials().then(
        (creds) => creds.accessToken,
      );
      final response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/search?q=$artist $album&type=album&limit=1',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      if (data['albums']?['items']?.isNotEmpty) {
        final albumUri = data['albums']['items'][0]['uri'];
        if (albumUri != null) {
          await SpotifySdk.play(spotifyUri: albumUri);
        }
      }
    } catch (e) {
      _logger.warning('Failed to play album: $e');
    }
  }

  Future<void> pause() async {
    await SpotifySdk.pause();
  }

  Future<void> resume() async {
    await SpotifySdk.resume();
  }

  Future<void> skipNext() async {
    await SpotifySdk.skipNext();
  }

  Future<void> skipPrevious() async {
    await SpotifySdk.skipPrevious();
  }
}
