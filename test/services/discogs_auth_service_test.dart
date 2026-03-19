import 'package:flutter_test/flutter_test.dart';
import 'package:needl/services/discogs_auth_service.dart';

void main() {
  group('DiscogsAuthService', () {
    test('singleton returns the same instance', () {
      final a = DiscogsAuthService();
      final b = DiscogsAuthService();
      expect(identical(a, b), isTrue);
    });

    test('connectedUsername is a ValueNotifier', () {
      final service = DiscogsAuthService();
      expect(service.connectedUsername, isNotNull);
    });
  });
}
