import 'package:flutter_test/flutter_test.dart';
import 'package:needl/services/discogs_service.dart';

void main() {
  group('DiscogsService', () {
    test('singleton returns the same instance', () {
      final a = DiscogsService();
      final b = DiscogsService();
      expect(identical(a, b), isTrue);
    });

    test('clearUsernameCache does not throw', () {
      DiscogsService().clearUsernameCache();
    });

    test('clearUsernameCache can be called multiple times', () {
      final service = DiscogsService();
      service.clearUsernameCache();
      service.clearUsernameCache();
    });
  });
}
