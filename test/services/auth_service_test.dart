import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:needl/services/auth_service.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupFakeSupabase();
  });

  group('AuthService', () {
    test('is a singleton', () {
      final a = AuthService();
      final b = AuthService();
      expect(a, same(b));
    });

    test('currentUser is null when not logged in', () {
      expect(AuthService().currentUser, isNull);
    });

    test('userId is null when not logged in', () {
      expect(AuthService().userId, isNull);
    });

    test('isLoggedIn is false when not logged in', () {
      expect(AuthService().isLoggedIn, isFalse);
    });

    test('authStateChanges returns a Stream', () {
      expect(AuthService().authStateChanges, isA<Stream>());
    });

    test('getProfile returns null when not logged in', () async {
      final profile = await AuthService().getProfile();
      expect(profile, isNull);
    });

    test('getTier returns free when no profile', () async {
      final tier = await AuthService().getTier();
      expect(tier, 'free');
    });

    test('updateProfile does nothing when not logged in', () async {
      // Should not throw
      await AuthService().updateProfile(displayName: 'Test');
    });
  });
}
