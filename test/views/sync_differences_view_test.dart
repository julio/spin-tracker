import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needl/sync_differences_view.dart';

void main() {
  Widget buildApp(
    List<Map<String, String>> needl,
    List<Map<String, String>> discogs,
  ) {
    return MaterialApp(
      home: SyncDifferencesView(
        needlAlbums: needl,
        discogsAlbums: discogs,
      ),
    );
  }

  group('SyncDifferencesView', () {
    testWidgets('shows "All sources match" when collections are identical',
        (tester) async {
      final albums = [
        {'artist': 'Radiohead', 'album': 'OK Computer'},
      ];
      await tester.pumpWidget(buildApp(albums, albums));

      expect(find.text('All sources match'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('shows "All sources match" when both are empty',
        (tester) async {
      await tester.pumpWidget(buildApp([], []));
      expect(find.text('All sources match'), findsOneWidget);
    });

    testWidgets('shows differences when Needl has extra albums',
        (tester) async {
      final needl = [
        {'artist': 'Radiohead', 'album': 'OK Computer'},
        {'artist': 'Radiohead', 'album': 'Kid A'},
      ];
      final discogs = [
        {'artist': 'Radiohead', 'album': 'OK Computer'},
      ];
      await tester.pumpWidget(buildApp(needl, discogs));

      expect(find.textContaining('In Needl but not in Discogs'), findsOneWidget);
      expect(find.textContaining('Kid A'), findsOneWidget);
    });

    testWidgets('shows differences when Discogs has extra albums',
        (tester) async {
      final needl = [
        {'artist': 'Radiohead', 'album': 'OK Computer'},
      ];
      final discogs = [
        {'artist': 'Radiohead', 'album': 'OK Computer'},
        {'artist': 'Pink Floyd', 'album': 'Animals'},
      ];
      await tester.pumpWidget(buildApp(needl, discogs));

      expect(find.textContaining('In Discogs but not in Needl'), findsOneWidget);
      expect(find.textContaining('Animals'), findsOneWidget);
    });

    testWidgets('shows both directions when collections differ',
        (tester) async {
      final needl = [
        {'artist': 'Beatles', 'album': 'Abbey Road'},
      ];
      final discogs = [
        {'artist': 'Beatles', 'album': 'Revolver'},
      ];
      await tester.pumpWidget(buildApp(needl, discogs));

      expect(find.textContaining('In Needl but not in Discogs'), findsOneWidget);
      expect(find.textContaining('In Discogs but not in Needl'), findsOneWidget);
      expect(find.textContaining('Abbey Road'), findsOneWidget);
      expect(find.textContaining('Revolver'), findsOneWidget);
    });

    testWidgets('shows correct counts in section headers', (tester) async {
      final needl = [
        {'artist': 'A', 'album': 'X'},
        {'artist': 'B', 'album': 'Y'},
        {'artist': 'C', 'album': 'Z'},
      ];
      await tester.pumpWidget(buildApp(needl, []));

      expect(find.textContaining('(3)'), findsOneWidget);
    });

    testWidgets('has Differences app bar title', (tester) async {
      await tester.pumpWidget(buildApp([], []));
      expect(find.text('Differences'), findsOneWidget);
    });

    testWidgets('matches despite formatting differences', (tester) async {
      final needl = [
        {'artist': "Guns N' Roses", 'album': 'Appetite For Destruction'},
      ];
      final discogs = [
        {'artist': 'Guns N Roses', 'album': 'Appetite for Destruction'},
      ];
      await tester.pumpWidget(buildApp(needl, discogs));

      expect(find.text('All sources match'), findsOneWidget);
    });
  });
}
