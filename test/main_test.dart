import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needl/main.dart';
import 'package:needl/auth/login_view.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupFakeSupabase();
  });

  group('NeedlApp', () {
    testWidgets('renders MaterialApp', (tester) async {
      await tester.pumpWidget(const NeedlApp());
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('has correct app title', (tester) async {
      await tester.pumpWidget(const NeedlApp());
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, 'Needl');
    });

    testWidgets('has both light and dark themes', (tester) async {
      await tester.pumpWidget(const NeedlApp());
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme, isNotNull);
      expect(app.darkTheme, isNotNull);
    });

    testWidgets('defaults to dark theme mode', (tester) async {
      await tester.pumpWidget(const NeedlApp());
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });

    testWidgets('uses Material 3', (tester) async {
      await tester.pumpWidget(const NeedlApp());
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme!.useMaterial3, isTrue);
    });
  });

  group('AuthGate', () {
    testWidgets('shows LoginView when no session', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthGate()));
      await tester.pump();

      // With fake Supabase and no login, AuthGate should render LoginView
      expect(find.byType(LoginView), findsOneWidget);
    });

    testWidgets('shows Needl branding via LoginView', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthGate()));
      await tester.pump();

      expect(find.text('Needl'), findsOneWidget);
    });
  });

  group('NeedlApp theme toggle', () {
    testWidgets('toggleTheme switches from dark to light', (tester) async {
      await tester.pumpWidget(const NeedlApp());
      await tester.pump();

      // Initially dark theme
      var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);

      // Get a context below NeedlApp to call toggleTheme
      final context = tester.element(find.byType(Scaffold).first);
      NeedlApp.of(context)?.toggleTheme();
      await tester.pump();

      // Now light theme
      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light);
    });

    testWidgets('toggleTheme switches back to dark', (tester) async {
      await tester.pumpWidget(const NeedlApp());
      await tester.pump();

      final context = tester.element(find.byType(Scaffold).first);

      // Toggle twice: dark → light → dark
      NeedlApp.of(context)?.toggleTheme();
      await tester.pump();
      NeedlApp.of(context)?.toggleTheme();
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });

    testWidgets('NeedlApp.of returns non-null inside widget tree',
        (tester) async {
      await tester.pumpWidget(const NeedlApp());
      await tester.pump();

      final context = tester.element(find.byType(Scaffold).first);
      expect(NeedlApp.of(context), isNotNull);
    });
  });
}
