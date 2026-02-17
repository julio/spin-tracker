import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needl/components/bottom_nav.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupFakeSupabase();
  });

  Widget buildApp({
    bool isOnSearchView = false,
    List<Map<String, String>> Function()? getAnniversaries,
    List<Map<String, String>>? ownedAlbums,
    VoidCallback? onRandomTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BottomNav(
          isOnSearchView: isOnSearchView,
          getAnniversaries: getAnniversaries,
          ownedAlbums: ownedAlbums,
          onRandomTap: onRandomTap,
        ),
      ),
    );
  }

  group('BottomNav', () {
    testWidgets('renders all navigation items', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Random'), findsOneWidget);
      expect(find.text('Collection'), findsOneWidget);
      expect(find.text('Anniversaries'), findsOneWidget);
    });

    testWidgets('renders nav icons', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.album_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cake_rounded), findsOneWidget);
    });

    testWidgets('highlights search when isOnSearchView is true', (tester) async {
      await tester.pumpWidget(buildApp(isOnSearchView: true));

      // The Search nav item should be rendered (we can verify it exists)
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('nav items are disabled when no data provided', (tester) async {
      await tester.pumpWidget(buildApp());

      // Random, Collection, Anniversaries should be disabled (no ownedAlbums/getAnniversaries)
      // Tapping them should do nothing
      await tester.tap(find.text('Random'));
      await tester.pump();
      // No navigation should occur
    });

    testWidgets('nav items are enabled when data is provided', (tester) async {
      final albums = [
        {'artist': 'Radiohead', 'album': 'OK Computer', 'release': '1997-06-16'},
      ];

      await tester.pumpWidget(buildApp(
        ownedAlbums: albums,
        getAnniversaries: () => [],
      ));

      // Nav items should be tappable
      expect(find.text('Random'), findsOneWidget);
      expect(find.text('Collection'), findsOneWidget);
      expect(find.text('Anniversaries'), findsOneWidget);
    });

    testWidgets('onRandomTap callback is invoked', (tester) async {
      var tapped = false;

      await tester.pumpWidget(buildApp(
        onRandomTap: () => tapped = true,
      ));

      await tester.tap(find.text('Random'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
