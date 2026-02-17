import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sets up a fake Supabase instance for testing.
/// Call this in setUpAll() for tests that need widgets with Supabase deps.
Future<void> setupFakeSupabase() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock SharedPreferences (needed by Supabase auth)
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/shared_preferences'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, dynamic>{};
      }
      return null;
    },
  );

  // Mock path_provider
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async {
      return '/tmp/test';
    },
  );

  try {
    await Supabase.initialize(
      url: 'https://fake.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZha2UiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYxNjk2MjAwMCwiZXhwIjoxOTMyNTM4MDAwfQ.fake_signature_for_testing',
    );
  } catch (_) {
    // Already initialized
  }
}
