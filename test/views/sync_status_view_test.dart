import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needl/sync_status_view.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupFakeSupabase();
  });

  group('SyncStatusView', () {
    testWidgets('renders AppBar with title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SyncStatusView()));
      await tester.pump();

      expect(find.text('Sync Status'), findsOneWidget);
    });

    testWidgets('shows Needl source card', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SyncStatusView()));
      await tester.pump();

      expect(find.text('Needl'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_sync_rounded), findsOneWidget);
    });

    testWidgets('shows Discogs Collection source card', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SyncStatusView()));
      await tester.pump();

      expect(find.text('Discogs Collection'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_rounded), findsOneWidget);
    });

    testWidgets('shows error status when Supabase unreachable', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SyncStatusView()));
      await tester.pump();
      await tester.pump();

      // Supabase is fake so Needl fetch fails, Discogs not connected
      expect(find.text('Unable to determine sync status'), findsOneWidget);
      expect(find.text('Some sources failed to load'), findsOneWidget);
    });

    testWidgets('shows warning icon in error state', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SyncStatusView()));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });

    testWidgets('shows Discogs not connected error', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SyncStatusView()));
      await tester.pump();

      // Discogs is not connected, so it should show the error
      expect(find.text('Failed to fetch count'), findsAtLeastNWidgets(1));
      expect(find.text('Discogs not connected'), findsOneWidget);
    });

    testWidgets('shows help text at bottom', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SyncStatusView()));
      await tester.pump();

      expect(
        find.text(
            'Compares your Needl collection with Discogs. Use the refresh button to pull latest data.'),
        findsOneWidget,
      );
    });

    testWidgets('shows retry button for Discogs error', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SyncStatusView()));
      await tester.pump();

      expect(find.text('Retry'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.refresh_rounded), findsAtLeastNWidgets(1));
    });

    testWidgets('loads async data and settles', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SyncStatusView()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      // After async load, should still show the view
      expect(find.text('Sync Status'), findsOneWidget);
    });

    testWidgets('retry button can be tapped', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SyncStatusView()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      // Find and tap the first Retry button
      final retryButtons = find.text('Retry');
      if (retryButtons.evaluate().isNotEmpty) {
        await tester.tap(retryButtons.first);
        await tester.pump();
      }
      expect(find.text('Sync Status'), findsOneWidget);
    });

    testWidgets('has Scaffold with AppBar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SyncStatusView()));
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows count cards', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SyncStatusView()));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      // Should show count cards even in error state
      expect(find.byType(Card), findsAtLeastNWidgets(2));
    });
  });
}
