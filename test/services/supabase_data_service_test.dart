import 'package:flutter_test/flutter_test.dart';
import 'package:needl/services/supabase_data_service.dart';

void main() {
  group('SupabaseDataService', () {
    test('singleton returns the same instance', () {
      final a = SupabaseDataService();
      final b = SupabaseDataService();
      expect(identical(a, b), isTrue);
    });
  });
}
