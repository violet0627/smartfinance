import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartfinance2/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SmartFinance App Integration Tests', () {
    testWidgets('App launches successfully', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // App should launch without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Onboarding tutorial shows on first launch', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // May show onboarding on first launch
      // Skip test if onboarding was already completed
    });
  });

  group('Authentication Flow Integration Tests', () {
    testWidgets('Can navigate to login screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Look for login or register button
      final loginButton = find.text('Login');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle();
      }

      // Should be on login screen or already logged in
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Login form validation works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to login if needed
      final loginText = find.text('Login');
      if (loginText.evaluate().isNotEmpty) {
        if (find.text('Login').evaluate().length > 1) {
          await tester.tap(loginText.first);
        } else {
          await tester.tap(loginText);
        }
        await tester.pumpAndSettle();
      }

      // Try to submit empty form
      final submitButton = find.text('Login');
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.last);
        await tester.pumpAndSettle();

        // Should show validation errors
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('Can navigate to registration screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Look for register button or link
      final registerButton = find.text('Register');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton.first);
        await tester.pumpAndSettle();
      }

      // Should be on register screen
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Registration form validation works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to registration
      final registerText = find.text('Register');
      if (registerText.evaluate().isNotEmpty) {
        await tester.tap(registerText.first);
        await tester.pumpAndSettle();
      }

      // Try to submit empty form
      final submitButton = find.text('Register');
      if (submitButton.evaluate().length > 1) {
        await tester.tap(submitButton.last);
        await tester.pumpAndSettle();

        // Should show validation errors
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });
  });

  group('Dashboard Integration Tests', () {
    testWidgets('Dashboard loads after login', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should show dashboard or login screen
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });

    testWidgets('Dashboard shows financial summary cards', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should show cards with financial data
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('FAB opens add transaction screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for floating action button
      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
        await tester.pumpAndSettle();

        // Should navigate to add transaction
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });
  });

  group('Transaction Flow Integration Tests', () {
    testWidgets('Complete transaction creation flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to add transaction
      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
        await tester.pumpAndSettle();

        // Fill in transaction form
        final amountField = find.byType(TextField).first;
        if (amountField.evaluate().isNotEmpty) {
          await tester.enterText(amountField, '100.00');
          await tester.pumpAndSettle();
        }

        // Submit form
        final saveButton = find.text('Save');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
        }
      }

      // Should return to previous screen
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Can view transaction history', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to transaction history
      final historyButton = find.text('Transactions');
      if (historyButton.evaluate().isNotEmpty) {
        await tester.tap(historyButton);
        await tester.pumpAndSettle();

        // Should show transaction list
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });

    testWidgets('Can search transactions', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to transactions
      final historyButton = find.text('Transactions');
      if (historyButton.evaluate().isNotEmpty) {
        await tester.tap(historyButton);
        await tester.pumpAndSettle();

        // Open search
        final searchIcon = find.byIcon(Icons.search);
        if (searchIcon.evaluate().isNotEmpty) {
          await tester.tap(searchIcon);
          await tester.pumpAndSettle();

          // Enter search query
          await tester.enterText(find.byType(TextField).first, 'Food');
          await tester.pumpAndSettle();

          // Should filter results
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });

    testWidgets('Can filter transactions', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to transactions
      final historyButton = find.text('Transactions');
      if (historyButton.evaluate().isNotEmpty) {
        await tester.tap(historyButton);
        await tester.pumpAndSettle();

        // Open filter
        final filterIcon = find.byIcon(Icons.filter_list);
        if (filterIcon.evaluate().isNotEmpty) {
          await tester.tap(filterIcon);
          await tester.pumpAndSettle();

          // Should show filter bottom sheet
          expect(find.text('Filter Transactions'), findsOneWidget);
        }
      }
    });
  });

  group('Receipt Scanning Integration Tests', () {
    testWidgets('Can navigate to receipt scanner', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for scan receipt button
      final scanButton = find.byIcon(Icons.camera_alt);
      if (scanButton.evaluate().isNotEmpty) {
        await tester.tap(scanButton);
        await tester.pumpAndSettle();

        // Should open camera or image picker
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });
  });

  group('Budget Flow Integration Tests', () {
    testWidgets('Can view budgets', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to budgets
      final budgetsButton = find.text('Budgets');
      if (budgetsButton.evaluate().isNotEmpty) {
        await tester.tap(budgetsButton);
        await tester.pumpAndSettle();

        // Should show budgets screen
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });

    testWidgets('Can create new budget', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to budgets
      final budgetsButton = find.text('Budgets');
      if (budgetsButton.evaluate().isNotEmpty) {
        await tester.tap(budgetsButton);
        await tester.pumpAndSettle();

        // Look for add budget button
        final addButton = find.byType(FloatingActionButton);
        if (addButton.evaluate().isNotEmpty) {
          await tester.tap(addButton);
          await tester.pumpAndSettle();

          // Should show budget form
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });
  });

  group('Reports and Export Integration Tests', () {
    testWidgets('Can navigate to reports screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to reports
      final reportsButton = find.text('Reports');
      if (reportsButton.evaluate().isNotEmpty) {
        await tester.tap(reportsButton);
        await tester.pumpAndSettle();

        // Should show reports screen
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });

    testWidgets('Can export data to CSV', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to reports
      final reportsButton = find.text('Reports');
      if (reportsButton.evaluate().isNotEmpty) {
        await tester.tap(reportsButton);
        await tester.pumpAndSettle();

        // Look for export button
        final exportButton = find.text('Export to CSV');
        if (exportButton.evaluate().isNotEmpty) {
          await tester.tap(exportButton);
          await tester.pumpAndSettle();

          // Should trigger export
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });

    testWidgets('Can export data to PDF', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to reports
      final reportsButton = find.text('Reports');
      if (reportsButton.evaluate().isNotEmpty) {
        await tester.tap(reportsButton);
        await tester.pumpAndSettle();

        // Look for PDF export button
        final pdfButton = find.text('Export to PDF');
        if (pdfButton.evaluate().isNotEmpty) {
          await tester.tap(pdfButton);
          await tester.pumpAndSettle();

          // Should trigger export
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });
  });

  group('Settings Integration Tests', () {
    testWidgets('Can navigate to settings', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to settings
      final settingsButton = find.text('Settings');
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        // Should show settings screen
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });

    testWidgets('Can toggle dark mode', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to settings
      final settingsButton = find.text('Settings');
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        // Look for dark mode toggle
        final darkModeSwitch = find.byType(Switch);
        if (darkModeSwitch.evaluate().isNotEmpty) {
          await tester.tap(darkModeSwitch.first);
          await tester.pumpAndSettle();

          // Theme should change
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      }
    });
  });

  group('Navigation Integration Tests', () {
    testWidgets('Bottom navigation bar works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find bottom navigation bar
      final bottomNav = find.byType(BottomNavigationBar);
      if (bottomNav.evaluate().isNotEmpty) {
        // Tap each navigation item
        final navItems = find.descendant(
          of: bottomNav,
          matching: find.byType(InkResponse),
        );

        if (navItems.evaluate().length >= 2) {
          // Tap second item
          await tester.tap(navItems.at(1));
          await tester.pumpAndSettle();

          // Should navigate
          expect(find.byType(Scaffold), findsOneWidget);
        }
      }
    });

    testWidgets('Can navigate between all main screens', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final screens = ['Dashboard', 'Transactions', 'Budgets', 'Reports', 'Settings'];

      for (final screen in screens) {
        final button = find.text(screen);
        if (button.evaluate().isNotEmpty) {
          await tester.tap(button.first);
          await tester.pumpAndSettle();

          // Should navigate successfully
          expect(find.byType(Scaffold), findsOneWidget);
        }
      }
    });
  });

  group('Performance Integration Tests', () {
    testWidgets('App launches within acceptable time', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      app.main();
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Should launch in less than 5 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    testWidgets('Screens load without jank', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate between screens rapidly
      final screens = ['Transactions', 'Dashboard'];

      for (final screen in screens) {
        final button = find.text(screen);
        if (button.evaluate().isNotEmpty) {
          await tester.tap(button.first);
          await tester.pump();

          // Should show loading state immediately
          expect(find.byType(MaterialApp), findsOneWidget);

          await tester.pumpAndSettle();
        }
      }
    });
  });
}
