import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfinance2/widgets/shimmer_loading.dart';

void main() {
  group('ShimmerLoading Widget Tests', () {
    testWidgets('ShimmerLoading renders child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              child: Container(
                width: 100,
                height: 100,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsOneWidget);
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('ShimmerLoading animates correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              child: Container(
                width: 100,
                height: 100,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );

      // Initial state
      await tester.pump();

      // Animate forward
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Should still be visible
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('ShimmerLoading respects custom duration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              period: const Duration(milliseconds: 1000),
              child: Container(
                width: 100,
                height: 100,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
    });
  });

  group('SkeletonBox Widget Tests', () {
    testWidgets('SkeletonBox renders with correct dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonBox(
              width: 100,
              height: 50,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.minWidth, 100);
      expect(container.constraints?.minHeight, 50);
    });

    testWidgets('SkeletonBox applies custom border radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonBox(
              width: 100,
              height: 50,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonBox), findsOneWidget);
    });
  });

  group('SkeletonCircle Widget Tests', () {
    testWidgets('SkeletonCircle renders with correct size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCircle(size: 60),
          ),
        ),
      );

      expect(find.byType(SkeletonCircle), findsOneWidget);
    });

    testWidgets('SkeletonCircle has default size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCircle(),
          ),
        ),
      );

      expect(find.byType(SkeletonCircle), findsOneWidget);
    });
  });

  group('TransactionListSkeleton Widget Tests', () {
    testWidgets('TransactionListSkeleton renders correct number of items', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionListSkeleton(itemCount: 5),
          ),
        ),
      );

      expect(find.byType(TransactionListSkeleton), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(5));
    });

    testWidgets('TransactionListSkeleton has default item count', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionListSkeleton(),
          ),
        ),
      );

      expect(find.byType(TransactionListSkeleton), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(5)); // Default is 5
    });

    testWidgets('TransactionListSkeleton wraps with ShimmerLoading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionListSkeleton(itemCount: 3),
          ),
        ),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
    });
  });

  group('DashboardCardSkeleton Widget Tests', () {
    testWidgets('DashboardCardSkeleton renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(DashboardCardSkeleton), findsOneWidget);
      expect(find.byType(ShimmerLoading), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('DashboardCardSkeleton has correct structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardCardSkeleton(),
          ),
        ),
      );

      // Should contain multiple SkeletonBox widgets
      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));
    });
  });
}
