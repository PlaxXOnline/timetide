import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/controller.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/core/models/view.dart';
import 'package:timetide/src/interaction/keyboard/focus_traversal.dart';
import 'package:timetide/src/interaction/keyboard/shortcut_handler.dart';

void main() {
  group('TideShortcutHandler', () {
    late TideController controller;

    setUp(() {
      controller = TideController(
        initialDate: DateTime(2024, 6, 15),
        initialView: TideView.week,
      );
    });

    tearDown(() => controller.dispose());

    testWidgets('arrow right navigates forward', (tester) async {
      final initialDate = controller.displayDate;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideShortcutHandler(
            controller: controller,
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(controller.displayDate.isAfter(initialDate), isTrue);
    });

    testWidgets('arrow left navigates backward', (tester) async {
      final initialDate = controller.displayDate;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideShortcutHandler(
            controller: controller,
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(controller.displayDate.isBefore(initialDate), isTrue);
    });

    testWidgets('T key navigates to today', (tester) async {
      controller.displayDate = DateTime(2020, 1, 1);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideShortcutHandler(
            controller: controller,
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.pump();

      final now = DateTime.now();
      expect(controller.displayDate.year, now.year);
      expect(controller.displayDate.month, now.month);
      expect(controller.displayDate.day, now.day);
    });

    testWidgets('Escape deselects all', (tester) async {
      final event = TideEvent(
        id: '1',
        subject: 'Test',
        startTime: DateTime(2024, 1, 1, 9),
        endTime: DateTime(2024, 1, 1, 10),
      );
      controller.selectEvent(event);
      expect(controller.selectedEvents, isNotEmpty);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideShortcutHandler(
            controller: controller,
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(controller.selectedEvents, isEmpty);
    });

    testWidgets('delete callback is invoked', (tester) async {
      var deleteCalled = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideShortcutHandler(
            controller: controller,
            onDeleteSelected: () => deleteCalled = true,
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();

      expect(deleteCalled, isTrue);
    });

    testWidgets('enter callback is invoked', (tester) async {
      var openCalled = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideShortcutHandler(
            controller: controller,
            onOpenEvent: () => openCalled = true,
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(openCalled, isTrue);
    });

    testWidgets('disabled handler does not process shortcuts', (tester) async {
      final initialDate = controller.displayDate;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideShortcutHandler(
            controller: controller,
            enabled: false,
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(controller.displayDate, initialDate);
    });

    testWidgets('custom shortcuts are invoked', (tester) async {
      var customCalled = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideShortcutHandler(
            controller: controller,
            customShortcuts: {
              const SingleActivator(LogicalKeyboardKey.keyQ): () =>
                  customCalled = true,
            },
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.pump();

      expect(customCalled, isTrue);
    });
  });

  group('TideFocusTraversal', () {
    testWidgets('renders child within FocusTraversalGroup', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: TideFocusTraversal(
            child: Text('Hello'),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(FocusTraversalGroup), findsAtLeast(1));
    });

    testWidgets('ordered helper wraps with FocusTraversalOrder',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideFocusTraversal(
            child: TideFocusTraversal.ordered(
              order: TideFocusOrder.headerToday,
              child: const Text('Today'),
            ),
          ),
        ),
      );

      expect(find.byType(FocusTraversalOrder), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    test('TideFocusOrder constants are properly ordered', () {
      expect(TideFocusOrder.headerBack, lessThan(TideFocusOrder.headerToday));
      expect(
          TideFocusOrder.headerToday, lessThan(TideFocusOrder.headerForward));
      expect(TideFocusOrder.headerForward,
          lessThan(TideFocusOrder.headerViewSwitcher));
      expect(
          TideFocusOrder.headerViewSwitcher, lessThan(TideFocusOrder.dateCells));
      expect(TideFocusOrder.dateCells, lessThan(TideFocusOrder.events));
      expect(
          TideFocusOrder.events, lessThan(TideFocusOrder.resourceHeaders));
    });
  });
}

