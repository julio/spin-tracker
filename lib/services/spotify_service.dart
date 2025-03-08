import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify/spotify.dart';
import 'package:logging/logging.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

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

  Future<bool> _checkSpotifyInstallation() async {
    try {
      final spotifyUri = Uri.parse('spotify://');
      final canLaunch = await canLaunchUrl(spotifyUri);
      _logger.info('Can launch Spotify URL: $canLaunch');
      return canLaunch;
    } catch (e) {
      _logger.warning('Error checking Spotify installation: $e');
      return false;
    }
  }

  Future<bool> connect() async {
    try {
      // First verify Spotify is installed
      final isInstalled = await _checkSpotifyInstallation();
      if (!isInstalled) {
        _logger.severe('Spotify app is not accessible via URL scheme');
        throw Exception(
          'Spotify app cannot be accessed. Please ensure it is installed and try again.',
        );
      }

      // Add a small delay to ensure Spotify has time to initialize
      await Future.delayed(const Duration(seconds: 2));

      // Try to initialize the connection
      _logger.info('Attempting to connect to Spotify...');
      _isConnected = await SpotifySdk.connectToSpotifyRemote(
        clientId: spotifyClientId,
        redirectUrl: spotifyRedirectUri,
        scope: 'app-remote-control streaming user-modify-playback-state',
      );

      if (_isConnected) {
        _logger.info('Successfully connected to Spotify');
      } else {
        _logger.warning(
          'Failed to connect to Spotify - connection returned false',
        );
      }

      return _isConnected;
    } catch (e) {
      _logger.severe('Failed to connect to Spotify: $e');
      if (e.toString().contains('CouldNotFindSpotifyApp')) {
        // Try launching Spotify manually
        try {
          final spotifyUri = Uri.parse('spotify://');
          await launchUrl(spotifyUri);
          // Wait a moment and try connecting again
          await Future.delayed(const Duration(seconds: 2));
          return await connect();
        } catch (launchError) {
          _logger.severe('Failed to launch Spotify: $launchError');
        }
      }
      rethrow;
    }
  }

  Future<void> playAlbum(String artist, String album) async {
    try {
      if (!_isConnected) {
        _logger.info('Not connected to Spotify, attempting to connect...');
        final connected = await connect();
        if (!connected) {
          throw Exception('Could not connect to Spotify');
        }
      }

      _logger.info('Getting Spotify access token...');
      final token = await _spotifyApi.getCredentials().then(
        (creds) => creds.accessToken,
      );

      final encodedQuery = Uri.encodeComponent('$artist $album');
      _logger.info('Searching for album: $artist - $album');

      final response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/search?q=$encodedQuery&type=album&limit=1',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      if (data['albums']?['items']?.isNotEmpty) {
        final albumUri = data['albums']['items'][0]['uri'];
        if (albumUri != null) {
          _logger.info('Found album URI: $albumUri, attempting to play...');
          await SpotifySdk.play(spotifyUri: albumUri);
          _logger.info('Successfully started playing: $artist - $album');
        } else {
          throw Exception('Album URI not found in Spotify response');
        }
      } else {
        throw Exception('Album not found on Spotify: $artist - $album');
      }
    } catch (e) {
      _logger.severe('Failed to play album: $e');
      rethrow;
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
