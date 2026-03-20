import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/drag_details.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/interaction/drag_drop/resize_handler.dart';

void main() {
  group('TideResizeHandler', () {
    final event = TideEvent(
      id: '1',
      subject: 'Test Event',
      startTime: DateTime(2024, 1, 1, 10, 0),
      endTime: DateTime(2024, 1, 1, 11, 0),
    );

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 200,
            height: 100,
            child: TideResizeHandler(
              event: event,
              child: const Center(child: Text('Event')),
            ),
          ),
        ),
      );

      expect(find.text('Event'), findsOneWidget);
      expect(find.byType(TideResizeHandler), findsOneWidget);
    });

    testWidgets('shows both resize handles by default', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 200,
            height: 100,
            child: TideResizeHandler(
              event: event,
              child: const Center(child: Text('Event')),
            ),
          ),
        ),
      );

      // Both handles are MouseRegion + GestureDetector pairs.
      expect(find.byType(MouseRegion), findsNWidgets(2));
      expect(find.byType(GestureDetector), findsNWidgets(2));
    });

    testWidgets('shows only start handle with startOnly', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 200,
            height: 100,
            child: TideResizeHandler(
              event: event,
              resizeDirection: TideResizeDirection.startOnly,
              child: const Center(child: Text('Event')),
            ),
          ),
        ),
      );

      expect(find.byType(MouseRegion), findsOneWidget);
    });

    testWidgets('shows only end handle with endOnly', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 200,
            height: 100,
            child: TideResizeHandler(
              event: event,
              resizeDirection: TideResizeDirection.endOnly,
              child: const Center(child: Text('Event')),
            ),
          ),
        ),
      );

      expect(find.byType(MouseRegion), findsOneWidget);
    });

    testWidgets('no handles when disabled', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 200,
            height: 100,
            child: TideResizeHandler(
              event: event,
              enabled: false,
              child: const Center(child: Text('Event')),
            ),
          ),
        ),
      );

      expect(find.text('Event'), findsOneWidget);
      // No MouseRegion handles when disabled.
      expect(find.byType(MouseRegion), findsNothing);
    });

    testWidgets('uses custom handle size', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 200,
            height: 100,
            child: TideResizeHandler(
              event: event,
              resizeHandleSize: 16.0,
              child: const Center(child: Text('Event')),
            ),
          ),
        ),
      );

      expect(find.byType(TideResizeHandler), findsOneWidget);
      // The handle size is applied internally; we verify the widget builds.
    });

    testWidgets('has Semantics label', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 200,
            height: 100,
            child: TideResizeHandler(
              event: event,
              child: const Center(child: Text('Event')),
            ),
          ),
        ),
      );

      expect(find.byType(Semantics), findsWidgets);
    });
  });

  group('TideResizeDirection', () {
    test('enum has three values', () {
      expect(TideResizeDirection.values, hasLength(3));
      expect(TideResizeDirection.values,
          contains(TideResizeDirection.both));
      expect(TideResizeDirection.values,
          contains(TideResizeDirection.startOnly));
      expect(TideResizeDirection.values,
          contains(TideResizeDirection.endOnly));
    });
  });
}
