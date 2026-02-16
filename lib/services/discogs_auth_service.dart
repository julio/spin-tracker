import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DiscogsAuthService {
  static final DiscogsAuthService _instance = DiscogsAuthService._internal();
  final _logger = Logger('DiscogsAuthService');

  factory DiscogsAuthService() => _instance;
  DiscogsAuthService._internal();

  /// Notifies listeners when Discogs connection status changes.
  final ValueNotifier<String?> connectedUsername = ValueNotifier(null);

  bool _initialized = false;

  /// Queries discogs_tokens via RLS to see if user is connected.
  /// Caches the result in [connectedUsername].
  Future<String?> getConnectedUsername() async {
    try {
      final response = await Supabase.instance.client
          .from('discogs_tokens')
          .select('discogs_username')
          .maybeSingle();

      final username = response?['discogs_username'] as String?;
      connectedUsername.value = username;
      return username;
    } catch (e) {
      _logger.warning('Error checking Discogs connection: $e');
      connectedUsername.value = null;
      return null;
    }
  }

  /// Initializes connection status on app start. Call once.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await getConnectedUsername();
  }

  /// Starts the OAuth 1.0a flow: calls Edge Function, opens browser.
  Future<void> startOAuthFlow() async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'discogs-request-token',
      );

      if (response.status != 200) {
        final error = response.data is Map ? response.data['error'] : 'Unknown error';
        throw Exception('Failed to get request token: $error');
      }

      final data = response.data is String
          ? jsonDecode(response.data) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;
      final authorizeUrl = data['authorize_url'] as String?;

      if (authorizeUrl == null) {
        throw Exception('No authorize URL returned');
      }

      final uri = Uri.parse(authorizeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open browser for Discogs authorization');
      }
    } catch (e) {
      _logger.severe('Error starting OAuth flow: $e');
      rethrow;
    }
  }

  /// Completes the OAuth flow after redirect. Called from deep link handler.
  Future<String?> completeOAuthFlow(String oauthToken, String oauthVerifier) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'discogs-access-token',
        body: {
          'oauth_token': oauthToken,
          'oauth_verifier': oauthVerifier,
        },
      );

      if (response.status != 200) {
        final error = response.data is Map ? response.data['error'] : 'Unknown error';
        throw Exception('Failed to exchange access token: $error');
      }

      final data = response.data is String
          ? jsonDecode(response.data) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;
      final username = data['discogs_username'] as String?;

      connectedUsername.value = username;
      return username;
    } catch (e) {
      _logger.severe('Error completing OAuth flow: $e');
      rethrow;
    }
  }

  /// Disconnects the user's Discogs account by deleting their token row.
  Future<void> disconnect() async {
    try {
      await Supabase.instance.client
          .from('discogs_tokens')
          .delete()
          .eq('user_id', Supabase.instance.client.auth.currentUser!.id);
      connectedUsername.value = null;
    } catch (e) {
      _logger.severe('Error disconnecting Discogs: $e');
      rethrow;
    }
  }
}
