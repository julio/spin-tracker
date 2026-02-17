import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needl/components/bottom_nav.dart';
import 'package:needl/random_album_view.dart';
import 'package:needl/discogs_collection_view.dart';
import 'package:needl/anniversaries_view.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupFakeSupabase();
  });

  group('BottomNav', () {
    testWidgets('renders all nav labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BottomNav())),
      );

      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Random'), findsOneWidget);
      expect(find.text('Collection'), findsOneWidget);
      expect(find.text('Anniversaries'), findsOneWidget);
    });

    testWidgets('renders all nav icons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BottomNav())),
      );

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.album_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cake_rounded), findsOneWidget);
    });

    testWidgets('renders theme toggle button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BottomNav())),
      );

      // Dark mode or light mode icon should be present
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Icon &&
              (w.icon == Icons.light_mode_rounded ||
                  w.icon == Icons.dark_mode_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Random does not navigate when no data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BottomNav())),
      );

      await tester.tap(find.text('Random'));
      await tester.pump();

      expect(find.byType(RandomAlbumView), findsNothing);
    });

    testWidgets('Collection does not navigate when no data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BottomNav())),
      );

      await tester.tap(find.text('Collection'));
      await tester.pump();

      expect(find.byType(DiscogsCollectionView), findsNothing);
    });

    testWidgets('navigates to Random view when data provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomNav(
              isOnSearchView: false,
              ownedAlbums: const [],
              getAnniversaries: () => [],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Random'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(RandomAlbumView), findsOneWidget);
    });

    testWidgets('navigates to Collection view when data provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomNav(
              isOnSearchView: false,
              ownedAlbums: const [],
              getAnniversaries: () => [],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Collection'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(DiscogsCollectionView), findsOneWidget);
    });

    testWidgets('navigates to Anniversaries view when data provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomNav(
              isOnSearchView: false,
              ownedAlbums: const [],
              getAnniversaries: () => [],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Anniversaries'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(AnniversariesView), findsOneWidget);
    });

    testWidgets('Search is not tappable when isOnSearchView is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomNav(
              isOnSearchView: true,
              ownedAlbums: const [],
              getAnniversaries: () => [],
            ),
          ),
        ),
      );

      // Search tap should not navigate (onTap is null)
      await tester.tap(find.text('Search'));
      await tester.pump();

      // Still on the same page
      expect(find.text('Search'), findsOneWidget);
    });
  });
}
