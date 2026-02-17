import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needl/add_record_view.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupFakeSupabase();
  });

  group('AddRecordView', () {
    testWidgets('renders AppBar with title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      expect(find.text('Add Record'), findsOneWidget);
    });

    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      expect(find.widgetWithText(TextFormField, 'Artist'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Album'), findsOneWidget);
      expect(find.text('Release Date'), findsOneWidget);
      expect(find.text('Acquired'), findsOneWidget);
    });

    testWidgets('shows "Tap to select" for release date', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      expect(find.text('Tap to select'), findsOneWidget);
    });

    testWidgets('shows current date for Acquired field', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(find.text(dateStr), findsOneWidget);
    });

    testWidgets('has calendar icons for date fields', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      expect(find.byIcon(Icons.calendar_today_rounded), findsNWidgets(2));
    });

    testWidgets('has Find Release Date button with search icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      expect(find.text('Find Release Date'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('has Save button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });

    testWidgets('validates empty artist', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Artist is required'), findsOneWidget);
    });

    testWidgets('validates empty album', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Artist'),
        'Radiohead',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Album is required'), findsOneWidget);
    });

    testWidgets('validates both empty fields at once', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Artist is required'), findsOneWidget);
      expect(find.text('Album is required'), findsOneWidget);
    });

    testWidgets('shows snackbar when searching without fields', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      await tester.tap(find.text('Find Release Date'));
      await tester.pump();

      expect(find.text('Enter artist and album first'), findsOneWidget);
    });

    testWidgets('fields accept text input', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Artist'),
        'Radiohead',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Album'),
        'OK Computer',
      );

      expect(find.text('Radiohead'), findsOneWidget);
      expect(find.text('OK Computer'), findsOneWidget);
    });

    testWidgets('opens release date picker on tap', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      await tester.tap(find.text('Tap to select'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('opens acquired date picker on tap', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await tester.ensureVisible(find.text(dateStr));
      await tester.tap(find.text(dateStr));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('shows error snackbar when save fails', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Artist'),
        'Radiohead',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Album'),
        'OK Computer',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));

      // Pump several times to let async microtasks resolve
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data ?? '').contains('Error saving record'),
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('has SingleChildScrollView', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('has Form widget', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRecordView()));

      expect(find.byType(Form), findsOneWidget);
    });
  });
}
