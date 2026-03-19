import 'package:flutter_test/flutter_test.dart';
import 'package:needl/services/spotify_service.dart';

void main() {
  group('SpotifyService', () {
    test('singleton returns the same instance', () {
      final a = SpotifyService();
      final b = SpotifyService();
      expect(identical(a, b), isTrue);
    });
  });
}
