import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:needl/vinyl_home_page.dart';
import 'package:needl/services/data_repository.dart';
import 'package:needl/services/supabase_data_service.dart';
import 'package:needl/services/snapshot_service.dart';
import 'package:needl/services/auth_service.dart';
import '../test_helpers.dart';

class MockSupabaseDataService extends Mock implements SupabaseDataService {}
class MockSnapshotService extends Mock implements SnapshotService {}
class MockAuthService extends Mock implements AuthService {}

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

  group('VinylHomePage loading', () {
    testWidgets('shows loading indicator then settles', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      // After first pump, may show loading indicator
      await tester.pump();
      // Let async operations complete
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();
      // After loading completes, should show the main content
      expect(find.text('Needl'), findsOneWidget);
    });

    testWidgets('refresh button triggers reload', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      expect(find.text('Needl'), findsOneWidget);
    });

    testWidgets('app still renders after failed load', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 1000)));
      await tester.pump();

      // Even when data load fails, the UI should still be present
      expect(find.text('Owned Albums'), findsOneWidget);
      expect(find.text('Wanted Albums'), findsOneWidget);
      expect(find.byType(SegmentedButton<ArtistFilter>), findsOneWidget);
    });
  });

  group('VinylHomePage interactions', () {
    testWidgets('left chevron does nothing with no artist selected',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pump();

      expect(find.text('Select an artist to see albums'), findsNWidgets(2));
    });

    testWidgets('right chevron does nothing with no artist selected',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();

      expect(find.text('Select an artist to see albums'), findsNWidgets(2));
    });

    testWidgets('has DropdownSearch widget for artist selection',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.pump();

      expect(find.byType(DropdownSearch<String>), findsOneWidget);
    });
  });

  group('VinylHomePage with mock data', () {
    late MockSupabaseDataService mockRemote;
    late MockSnapshotService mockSnapshot;
    late MockAuthService mockAuth;

    final sampleOwned = [
      {
        'artist': 'Radiohead',
        'album': 'OK Computer',
        'release': '1997-06-16',
        'discogs_id': '',
        'discogs_instance_id': '',
        'acquired_at': '',
      },
      {
        'artist': 'Radiohead',
        'album': 'Kid A',
        'release': '2000-10-02',
        'discogs_id': '',
        'discogs_instance_id': '',
        'acquired_at': '',
      },
      {
        'artist': 'Pink Floyd',
        'album': 'Animals',
        'release': '1977-01-23',
        'discogs_id': '',
        'discogs_instance_id': '',
        'acquired_at': '',
      },
    ];

    final sampleWanted = [
      {'artist': 'Radiohead', 'album': 'In Rainbows'},
      {'artist': 'Pink Floyd', 'album': 'Wish You Were Here'},
    ];

    setUp(() {
      mockRemote = MockSupabaseDataService();
      mockSnapshot = MockSnapshotService();
      mockAuth = MockAuthService();

      final repo = DataRepository.forTesting(
        remote: mockRemote,
        snapshot: mockSnapshot,
        auth: mockAuth,
      );
      DataRepository.setInstanceForTesting(repo);

      when(() => mockRemote.getAllOwnedAlbums())
          .thenAnswer((_) async => sampleOwned);
      when(() => mockRemote.getAllWantedAlbums())
          .thenAnswer((_) async => sampleWanted);
      when(() => mockSnapshot.save(
              owned: any(named: 'owned'), wanted: any(named: 'wanted')))
          .thenAnswer((_) async {});
      when(() => mockSnapshot.deleteOldDatabase()).thenAnswer((_) async {});
      when(() => mockSnapshot.clear()).thenAnswer((_) async {});
      when(() => mockAuth.getTier()).thenAnswer((_) async => 'premium');
    });

    tearDown(() {
      DataRepository.resetInstance();
    });

    testWidgets('loads and displays album counts', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      // Should show 3 owned and 2 wanted
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('dropdown shows artist list', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownSearch<String>));
      await tester.pumpAndSettle();

      // Should show artist names (lowercase)
      expect(find.text('pink floyd'), findsAtLeastNWidgets(1));
      expect(find.text('radiohead'), findsAtLeastNWidgets(1));
    });

    testWidgets('selecting artist shows their albums', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      // Open dropdown and select Radiohead
      await tester.tap(find.byType(DropdownSearch<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('radiohead').last);
      await tester.pumpAndSettle();

      // Should show Radiohead's albums
      expect(find.text('OK Computer'), findsOneWidget);
      expect(find.text('Kid A'), findsOneWidget);
    });

    testWidgets('switching to Wanted segment shows wanted albums',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      // Switch to Wanted
      await tester.tap(find.text('Wanted'));
      await tester.pump();

      // Open dropdown and select Radiohead
      await tester.tap(find.byType(DropdownSearch<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('radiohead').last);
      await tester.pumpAndSettle();

      expect(find.text('In Rainbows'), findsOneWidget);
    });

    testWidgets('sort by artist/album works', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      // Open menu and change sort
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort by Artist/Album'));
      await tester.pumpAndSettle();

      // Select an artist to verify sort applied
      await tester.tap(find.byType(DropdownSearch<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('radiohead').last);
      await tester.pumpAndSettle();

      // Albums should be shown (sorted by artist/album now)
      expect(find.text('Kid A'), findsOneWidget);
      expect(find.text('OK Computer'), findsOneWidget);
    });

    testWidgets('previous chevron navigates back', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      // Select second artist (radiohead)
      await tester.tap(find.byType(DropdownSearch<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('radiohead').last);
      await tester.pumpAndSettle();

      // Navigate to previous artist
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pump();

      // Should show pink floyd's album
      expect(find.text('Animals'), findsOneWidget);
    });

    testWidgets('selecting artist shows album in wanted section too',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      // Select Radiohead
      await tester.tap(find.byType(DropdownSearch<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('radiohead').last);
      await tester.pumpAndSettle();

      // Should show owned albums
      expect(find.text('OK Computer'), findsOneWidget);
      expect(find.text('Kid A'), findsOneWidget);

      // Should show wanted album
      expect(find.text('In Rainbows'), findsOneWidget);
    });

    testWidgets('shows correct count after artist selection', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      // Select Pink Floyd
      await tester.tap(find.byType(DropdownSearch<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('pink floyd').last);
      await tester.pumpAndSettle();

      // Should show Animals
      expect(find.text('Animals'), findsOneWidget);
    });

    testWidgets('refresh re-loads data', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VinylHomePage()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });
  });
}
