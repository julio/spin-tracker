import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needl/discogs_collection_view.dart';
import 'package:needl/services/discogs_auth_service.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupFakeSupabase();
  });

  Widget buildApp() {
    return MaterialApp(
      home: DiscogsCollectionView(
        getAnniversaries: () => [],
        ownedAlbums: const [],
      ),
    );
  }

  group('DiscogsCollectionView not connected', () {
    setUp(() {
      DiscogsAuthService().connectedUsername.value = null;
    });

    testWidgets('renders AppBar with title', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Collection'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows sort button in AppBar', (tester) async {
      await tester.pumpWidget(buildApp());

      // Default sort is desc, so arrow_downward is shown
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });

    testWidgets('shows not connected message when Discogs is disconnected',
        (tester) async {
      await tester.pumpWidget(buildApp());

      expect(
        find.text(
            'Connect your Discogs account in Settings to browse your collection.'),
        findsOneWidget,
      );
    });

    testWidgets('shows Open Settings button when not connected',
        (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    });

    testWidgets('shows album icon in not connected state', (tester) async {
      await tester.pumpWidget(buildApp());

      // album_rounded appears in the not-connected placeholder and in BottomNav
      expect(find.byIcon(Icons.album_rounded), findsAtLeastNWidgets(1));
    });

    testWidgets('has BottomNav', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Random'), findsOneWidget);
      expect(find.text('Anniversaries'), findsOneWidget);
    });

    testWidgets('Open Settings navigates to SettingsView', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Discogs'), findsOneWidget);
    });
  });

  group('DiscogsCollectionView connected', () {
    setUp(() {
      DiscogsAuthService().connectedUsername.value = 'testuser';
    });

    tearDown(() {
      DiscogsAuthService().connectedUsername.value = null;
    });

    testWidgets('shows Records header when connected', (tester) async {
      await tester.pumpWidget(buildApp());
      // Check on first frame before async call resets the username
      expect(find.text('Records'), findsOneWidget);
    });

    testWidgets('does not show not-connected message when connected',
        (tester) async {
      await tester.pumpWidget(buildApp());

      expect(
        find.text(
            'Connect your Discogs account in Settings to browse your collection.'),
        findsNothing,
      );
    });

    testWidgets('does not show Open Settings when connected', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Open Settings'), findsNothing);
    });

    testWidgets('shows GridView for releases', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('has BottomNav when connected', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Random'), findsOneWidget);
    });
  });
}
