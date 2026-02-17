import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needl/anniversaries_view.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupFakeSupabase();
  });

  Widget buildApp({List<Map<String, String>> anniversaries = const []}) {
    return MaterialApp(
      home: AnniversariesView(
        anniversaries: anniversaries,
        ownedAlbums: const [],
        getAnniversaries: () => [],
      ),
    );
  }

  group('AnniversariesView', () {
    testWidgets('renders AppBar with title', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Anniversaries'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows empty state when no anniversaries', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(
          find.text('No anniversaries today or tomorrow'), findsOneWidget);
    });

    testWidgets('shows cake icon in empty state', (tester) async {
      await tester.pumpWidget(buildApp());

      // Cake icon appears in empty state and in BottomNav
      expect(find.byIcon(Icons.cake_rounded), findsAtLeastNWidgets(1));
    });

    testWidgets('has BottomNav', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Random'), findsOneWidget);
      expect(find.text('Collection'), findsOneWidget);
    });

    testWidgets('shows album details when anniversaries exist',
        (tester) async {
      final anniversaries = [
        {
          'artist': 'Radiohead',
          'album': 'OK Computer',
          'release': '1997-06-16',
          'isToday': 'Today',
        },
        {
          'artist': 'Nirvana',
          'album': 'Nevermind',
          'release': '1991-09-24',
          'isToday': 'Tomorrow',
        },
      ];

      await tester.pumpWidget(buildApp(anniversaries: anniversaries));
      await tester.pump();

      expect(find.text('OK Computer'), findsOneWidget);
      expect(find.text('Radiohead'), findsOneWidget);
      expect(find.text('1997-06-16'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);

      expect(find.text('Nevermind'), findsOneWidget);
      expect(find.text('Nirvana'), findsOneWidget);
      expect(find.text('1991-09-24'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
    });

    testWidgets('renders grid view with anniversaries', (tester) async {
      final anniversaries = [
        {
          'artist': 'Radiohead',
          'album': 'OK Computer',
          'release': '1997-06-16',
          'isToday': 'Today',
        },
      ];

      await tester.pumpWidget(buildApp(anniversaries: anniversaries));
      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });

    testWidgets('does not show empty state when anniversaries exist',
        (tester) async {
      final anniversaries = [
        {
          'artist': 'Radiohead',
          'album': 'OK Computer',
          'release': '1997-06-16',
          'isToday': 'Today',
        },
      ];

      await tester.pumpWidget(buildApp(anniversaries: anniversaries));
      await tester.pump();

      expect(
          find.text('No anniversaries today or tomorrow'), findsNothing);
    });
  });
}
