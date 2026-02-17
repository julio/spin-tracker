import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needl/vinyl_home_page.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupFakeSupabase();
  });

  group('VinylHomePage', () {
    testWidgets('renders AppBar with Needl title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      expect(find.text('Needl'), findsOneWidget);
    });

    testWidgets('has add button in AppBar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('has refresh button in AppBar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('has sync status button in AppBar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      expect(find.byIcon(Icons.analytics_rounded), findsOneWidget);
    });

    testWidgets('has overflow menu button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });

    testWidgets('shows Owned/Wanted segmented button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      expect(find.text('Owned'), findsOneWidget);
      expect(find.text('Wanted'), findsOneWidget);
      expect(find.byType(SegmentedButton<ArtistFilter>), findsOneWidget);
    });

    testWidgets('shows artist navigation arrows', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('shows Owned Albums section header', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      expect(find.text('Owned Albums'), findsOneWidget);
    });

    testWidgets('shows Wanted Albums section header', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      expect(find.text('Wanted Albums'), findsOneWidget);
    });

    testWidgets('shows empty state messages when no artist selected',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      expect(
          find.text('Select an artist to see albums'), findsNWidgets(2));
    });

    testWidgets('shows album counts as 0 initially', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      expect(find.text('0'), findsNWidgets(2));
    });

    testWidgets('has BottomNav with search highlighted', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Random'), findsOneWidget);
      expect(find.text('Collection'), findsOneWidget);
      expect(find.text('Anniversaries'), findsOneWidget);
    });

    testWidgets('overflow menu contains sort and settings options',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      // Open the overflow menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Sort by Release Date'), findsOneWidget);
      expect(find.text('Sort by Artist/Album'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });
  });

  group('VinylHomePage navigation', () {
    testWidgets('add button navigates to AddRecordView', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      // Let real I/O (snapshot file check) complete so isLoading becomes false
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Add Record'), findsAtLeastNWidgets(1));
    });

    testWidgets('sync status button navigates to SyncStatusView',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.analytics_rounded));
      await tester.pump();
      await tester.pump();

      expect(find.text('Sync Status'), findsOneWidget);
    });
  });

  group('VinylHomePage overflow menu', () {
    testWidgets('sort by Release Date from menu', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sort by Release Date'));
      await tester.pumpAndSettle();

      // Menu dismissed, still on home page
      expect(find.text('Needl'), findsOneWidget);
    });

    testWidgets('sort by Artist/Album from menu', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sort by Artist/Album'));
      await tester.pumpAndSettle();

      expect(find.text('Needl'), findsOneWidget);
    });

    testWidgets('navigates to Settings from menu', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Should navigate to SettingsView
      expect(find.text('Discogs'), findsOneWidget);
    });
  });

  group('VinylHomePage segments', () {
    testWidgets('toggles to Wanted segment', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      await tester.tap(find.text('Wanted'));
      await tester.pump();

      // Both sections still visible
      expect(find.text('Owned Albums'), findsOneWidget);
      expect(find.text('Wanted Albums'), findsOneWidget);
    });

    testWidgets('toggles back to Owned segment', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      // Toggle to Wanted then back to Owned
      await tester.tap(find.text('Wanted'));
      await tester.pump();

      await tester.tap(find.text('Owned'));
      await tester.pump();

      expect(find.text('Owned Albums'), findsOneWidget);
    });
  });

  group('VinylHomePage state', () {
    testWidgets('SortOption enum has correct values', (tester) async {
      expect(SortOption.releaseDate, isNotNull);
      expect(SortOption.artistAlbum, isNotNull);
    });

    testWidgets('ArtistFilter enum has correct values', (tester) async {
      expect(ArtistFilter.owned, isNotNull);
      expect(ArtistFilter.wanted, isNotNull);
    });
  });
}
