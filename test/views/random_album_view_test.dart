import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needl/random_album_view.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupFakeSupabase();
  });

  Widget buildApp({List<Map<String, String>> ownedAlbums = const []}) {
    return MaterialApp(
      home: RandomAlbumView(
        ownedAlbums: ownedAlbums,
        getAnniversaries: () => [],
      ),
    );
  }

  group('RandomAlbumView', () {
    testWidgets('renders AppBar with title', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('Random Album'), findsOneWidget);
    });

    testWidgets('does not show back button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // automaticallyImplyLeading is false
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('shows "No albums available" with empty list', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('No albums available'), findsOneWidget);
    });

    testWidgets('has BottomNav', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Random'), findsOneWidget);
      expect(find.text('Collection'), findsOneWidget);
      expect(find.text('Anniversaries'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      // With albums, it starts loading (fetchCoverArt)
      final albums = [
        {
          'artist': 'Radiohead',
          'album': 'OK Computer',
          'release': '1997-06-16',
        },
      ];

      await tester.pumpWidget(buildApp(ownedAlbums: albums));
      // First frame: isLoading = true
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('shows album info after cover art fetch fails', (tester) async {
      final albums = [
        {
          'artist': 'Radiohead',
          'album': 'OK Computer',
          'release': '1997-06-16',
        },
      ];

      await tester.pumpWidget(buildApp(ownedAlbums: albums));

      // Let the real I/O (Supabase call) fail
      await tester.runAsync(
          () => Future.delayed(const Duration(seconds: 3)));
      await tester.pump();

      expect(find.text('OK Computer'), findsOneWidget);
      expect(find.text('Radiohead'), findsOneWidget);
      expect(find.text('1997-06-16'), findsOneWidget);
    });

    testWidgets('shows album icon when no cover art', (tester) async {
      final albums = [
        {
          'artist': 'Radiohead',
          'album': 'OK Computer',
          'release': '1997-06-16',
        },
      ];

      await tester.pumpWidget(buildApp(ownedAlbums: albums));

      await tester.runAsync(
          () => Future.delayed(const Duration(seconds: 3)));
      await tester.pump();

      // No cover art → shows album_rounded icon
      expect(find.byIcon(Icons.album_rounded), findsAtLeastNWidgets(1));
    });

    testWidgets('has shuffle icon in BottomNav', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
    });
  });
}
