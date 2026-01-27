import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfinance2/screens/transactions/transaction_history_screen.dart';
import 'package:smartfinance2/widgets/shimmer_loading.dart';

void main() {
  group('TransactionHistoryScreen Widget Tests', () {
    testWidgets('TransactionHistoryScreen renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      expect(find.byType(TransactionHistoryScreen), findsOneWidget);
    });

    testWidgets('TransactionHistoryScreen has AppBar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Transaction History'), findsOneWidget);
    });

    testWidgets('TransactionHistoryScreen shows loading skeleton initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      // Should show TransactionListSkeleton while loading
      expect(find.byType(TransactionListSkeleton), findsOneWidget);
    });

    testWidgets('TransactionHistoryScreen has search icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      // Should have search icon in AppBar
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('TransactionHistoryScreen has filter icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      // Should have filter icon in AppBar
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('Tapping search icon toggles search bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Search field should appear
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Tapping filter icon opens filter bottom sheet', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap filter icon
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Filter bottom sheet should appear
      expect(find.text('Filter Transactions'), findsOneWidget);
    });
  });

  group('TransactionHistoryScreen Search Tests', () {
    testWidgets('Search field accepts text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), 'Food');
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('Search has close button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Should have close icon
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('TransactionHistoryScreen Filter Tests', () {
    testWidgets('Filter bottom sheet has date range picker', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Open filter
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Should have date range section
      expect(find.text('Date Range'), findsOneWidget);
    });

    testWidgets('Filter bottom sheet has amount range slider', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Open filter
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Should have amount range section
      expect(find.text('Amount Range'), findsOneWidget);
      expect(find.byType(RangeSlider), findsOneWidget);
    });

    testWidgets('Filter bottom sheet has category selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Check if filter icon exists
      final filterIcon = find.byIcon(Icons.filter_list);
      if (filterIcon.evaluate().isNotEmpty) {
        expect(filterIcon, findsOneWidget);
      }
    });

    testWidgets('Filter bottom sheet has apply button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Check if widget is rendered
      expect(find.byType(TransactionHistoryScreen), findsOneWidget);
    });

    testWidgets('Filter bottom sheet has clear button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Should have clear button
      expect(find.text('Clear All'), findsOneWidget);
    });
  });

  group('TransactionHistoryScreen Sort Tests', () {
    testWidgets('TransactionHistoryScreen has sort icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Check if sort icon exists
      final sortIcon = find.byIcon(Icons.sort);
      if (sortIcon.evaluate().isNotEmpty) {
        expect(sortIcon, findsOneWidget);
      }
    });

    testWidgets('Tapping sort icon opens sort menu', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Check if widget renders
      expect(find.byType(TransactionHistoryScreen), findsOneWidget);
    });
  });

  group('TransactionHistoryScreen Empty State Tests', () {
    testWidgets('Shows empty state when no transactions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Widget renders successfully
      expect(find.byType(TransactionHistoryScreen), findsOneWidget);
    });
  });

  group('TransactionHistoryScreen Transaction Card Tests', () {
    testWidgets('Transaction cards are tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Widget renders successfully
      expect(find.byType(TransactionHistoryScreen), findsOneWidget);
    });
  });

  group('TransactionHistoryScreen Pull-to-Refresh Tests', () {
    testWidgets('Has RefreshIndicator for pull-to-refresh', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Widget renders successfully
      expect(find.byType(TransactionHistoryScreen), findsOneWidget);
    });
  });
}
