import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:needl/auth/login_view.dart';
import 'package:needl/auth/signup_view.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupFakeSupabase();
  });

  group('LoginView', () {
    testWidgets('renders login form', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginView()),
      );

      expect(find.text('Needl'), findsOneWidget);
      expect(find.text('Your vinyl collection tracker'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('has email and password fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginView()),
      );

      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    });

    testWidgets('validates empty email', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginView()),
      );

      // Tap sign in without filling fields
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('validates empty password', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginView()),
      );

      // Fill email but not password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows error when forgot password with empty email',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginView()),
      );

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email first'), findsOneWidget);
    });

    testWidgets('shows error after failed sign in', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginView()),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Sign-in to fake Supabase fails, showing an error text
      // The error text contains "Exception" or similar error info
      expect(
        find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').contains('Exception')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('navigates to SignupView when Sign Up tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginView()),
      );

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.byType(SignupView), findsOneWidget);
    });
  });

  group('SignupView', () {
    testWidgets('renders signup form', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SignupView()),
      );

      // "Create Account" appears in AppBar and button
      expect(find.text('Create Account'), findsNWidgets(2));
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Confirm Password'), findsOneWidget);
    });

    testWidgets('validates empty fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SignupView()),
      );

      // Find and tap the Create Account button (the FilledButton, not the AppBar text)
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('validates short password', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SignupView()),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        '123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        '123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('validates password mismatch', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SignupView()),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'different',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('shows loading indicator when signing up', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SignupView()),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pump();

      // After tapping, loading indicator should appear
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
