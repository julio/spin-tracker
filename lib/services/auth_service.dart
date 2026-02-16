import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  String? get userId => currentUser?.id;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<bool> signInWithApple() async {
    return _client.auth.signInWithOAuth(
      OAuthProvider.apple,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final uid = userId;
    if (uid == null) return null;
    final response =
        await _client.from('profiles').select().eq('id', uid).single();
    return response;
  }

  Future<void> updateProfile({String? displayName, String? discogsToken, String? discogsUsername}) async {
    final uid = userId;
    if (uid == null) return;
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (discogsToken != null) updates['discogs_token'] = discogsToken;
    if (discogsUsername != null) updates['discogs_username'] = discogsUsername;
    if (updates.isEmpty) return;
    await _client.from('profiles').update(updates).eq('id', uid);
  }

  Future<String> getTier() async {
    final profile = await getProfile();
    return profile?['tier'] as String? ?? 'free';
  }
}
