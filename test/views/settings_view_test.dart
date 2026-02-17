import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needl/settings_view.dart';
import 'package:needl/services/discogs_auth_service.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupFakeSupabase();
  });

  group('SettingsView not connected', () {
    setUp(() {
      DiscogsAuthService().connectedUsername.value = null;
    });

    testWidgets('renders Settings title in AppBar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pump();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows Discogs section header', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pump();

      expect(find.text('Discogs'), findsOneWidget);
    });

    testWidgets('shows connect description when not connected', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Connect your Discogs account to sync your vinyl collection.'),
        findsOneWidget,
      );
    });

    testWidgets('shows Premium feature badge for free tier', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pumpAndSettle();

      expect(find.text('Premium feature'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    });

    testWidgets('does not show Connect Discogs button for free tier',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pumpAndSettle();

      expect(find.text('Connect Discogs'), findsNothing);
    });

    testWidgets('does not show Disconnect button when not connected',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pumpAndSettle();

      expect(find.text('Disconnect'), findsNothing);
    });

    testWidgets('has a Card widget wrapping Discogs content', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('uses ListView as body', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('SettingsView connected state', () {
    setUp(() {
      DiscogsAuthService().connectedUsername.value = 'testuser';
    });

    tearDown(() {
      DiscogsAuthService().connectedUsername.value = null;
    });

    testWidgets('shows connected username', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pumpAndSettle();

      expect(find.text('Connected as testuser'), findsOneWidget);
    });

    testWidgets('shows Disconnect button when connected', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Disconnect'), findsOneWidget);
    });

    testWidgets('shows check circle icon when connected', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('does not show Premium feature badge when connected',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pumpAndSettle();

      expect(find.text('Premium feature'), findsNothing);
    });

    testWidgets('does not show connect description when connected',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Connect your Discogs account to sync your vinyl collection.'),
        findsNothing,
      );
    });

    testWidgets('shows disconnect confirmation dialog', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Disconnect'));
      await tester.pumpAndSettle();

      expect(find.text('Disconnect Discogs'), findsOneWidget);
      expect(
        find.text(
            'This will remove your Discogs connection. You can reconnect at any time.'),
        findsOneWidget,
      );
    });

    testWidgets('dismisses disconnect dialog on Cancel', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Disconnect'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed, back to settings
      expect(find.text('Connected as testuser'), findsOneWidget);
      expect(find.text('Disconnect Discogs'), findsNothing);
    });
  });
}
