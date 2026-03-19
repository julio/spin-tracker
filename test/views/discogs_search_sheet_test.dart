import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needl/discogs_search_sheet.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupFakeSupabase();
  });

  Widget buildApp() {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDiscogsSearchSheet(
                context,
                artist: 'Radiohead',
                album: 'OK Computer',
                releaseDate: '1997-06-16',
              );
            },
            child: const Text('Open Sheet'),
          ),
        ),
      ),
    );
  }

  testWidgets('showDiscogsSearchSheet opens a bottom sheet', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open Sheet'));
    await tester.pump();

    // The sheet should appear with "Add to Discogs" title
    expect(find.text('Add to Discogs'), findsOneWidget);
  });

  testWidgets('search sheet shows Skip button', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open Sheet'));
    await tester.pump();

    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('search sheet shows loading indicator initially', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open Sheet'));
    await tester.pump();

    // While searching, should show a progress indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('search sheet shows error after failed search', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open Sheet'));
    await tester.pump();

    // Let the search fail (fake Supabase will return error)
    await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 500)));
    await tester.pump();

    // Should show error text
    expect(find.textContaining('Error searching Discogs'), findsOneWidget);
  });

  testWidgets('Skip button is a TextButton', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open Sheet'));
    await tester.pump();

    expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);
  });

  testWidgets('sheet has DraggableScrollableSheet', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open Sheet'));
    await tester.pump();

    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
  });

  testWidgets('sheet has a Divider', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open Sheet'));
    await tester.pump();

    expect(find.byType(Divider), findsAtLeastNWidgets(1));
  });
}
