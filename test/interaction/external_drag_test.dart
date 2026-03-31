import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/drag_details.dart';
import 'package:timetide/src/interaction/drag_drop/external_drag.dart';

void main() {
  group('TideExternalDragScope', () {
    testWidgets('of() returns notifier from ancestor', (tester) async {
      TideExternalDragNotifier? foundNotifier;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideExternalDragScope(
            child: Builder(
              builder: (context) {
                foundNotifier = TideExternalDragScope.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(foundNotifier, isNotNull);
      expect(foundNotifier, isA<TideExternalDragNotifier>());
    });

    testWidgets('of() returns null when no ancestor', (tester) async {
      TideExternalDragNotifier? foundNotifier;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              foundNotifier = TideExternalDragScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(foundNotifier, isNull);
    });
  });

  group('TideExternalDragNotifier', () {
    test('drop notifies listeners with data and position', () {
      final notifier = TideExternalDragNotifier();
      addTearDown(notifier.dispose);

      TideExternalDragData? receivedData;
      Offset? receivedPosition;

      notifier.addListener(() {
        receivedData = notifier.data;
        receivedPosition = notifier.position;
      });

      const data = TideExternalDragData(
        subject: 'Test',
        duration: Duration(hours: 1),
      );
      notifier.drop(data, const Offset(100, 200));

      expect(receivedData, isNotNull);
      expect(receivedData!.subject, 'Test');
      expect(receivedPosition, const Offset(100, 200));
    });

    test('data and position are cleared after drop notification', () {
      final notifier = TideExternalDragNotifier();
      addTearDown(notifier.dispose);

      const data = TideExternalDragData(
        subject: 'Test',
        duration: Duration(hours: 1),
      );
      notifier.drop(data, const Offset(100, 200));

      // After drop, data and position should be null.
      expect(notifier.data, isNull);
      expect(notifier.position, isNull);
    });
  });

  group('TideDragTarget', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideExternalDragScope(
            child: TideDragTarget(
              dropTime: DateTime(2024, 1, 1, 10, 0),
              child: const Text('Target'),
            ),
          ),
        ),
      );

      expect(find.text('Target'), findsOneWidget);
    });

    testWidgets('receives drop when within hit bounds', (tester) async {
      TideExternalDragEndDetails? receivedDetails;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideExternalDragScope(
            child: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: TideDragTarget(
                  dropTime: DateTime(2024, 1, 1, 10, 0),
                  dropResourceId: 'room-a',
                  onExternalDragEnd: (details) {
                    receivedDetails = details;
                  },
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );

      // Get the center position of the target.
      final targetCenter = tester.getCenter(find.byType(TideDragTarget));

      // Simulate a drop via the notifier.
      final notifier = TideExternalDragScope.of(
        tester.element(find.byType(TideDragTarget)),
      );
      expect(notifier, isNotNull);

      const data = TideExternalDragData(
        subject: 'Meeting',
        duration: Duration(hours: 1),
      );
      notifier!.drop(data, targetCenter);

      expect(receivedDetails, isNotNull);
      expect(receivedDetails!.data.subject, 'Meeting');
      expect(receivedDetails!.dropTime, DateTime(2024, 1, 1, 10, 0));
      expect(receivedDetails!.dropResourceId, 'room-a');
    });

    testWidgets('ignores drop when outside hit bounds', (tester) async {
      TideExternalDragEndDetails? receivedDetails;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideExternalDragScope(
            child: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: TideDragTarget(
                  dropTime: DateTime(2024, 1, 1, 10, 0),
                  onExternalDragEnd: (details) {
                    receivedDetails = details;
                  },
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );

      // Drop at a position far outside the target.
      final notifier = TideExternalDragScope.of(
        tester.element(find.byType(TideDragTarget)),
      );
      const data = TideExternalDragData(
        subject: 'Meeting',
        duration: Duration(hours: 1),
      );
      notifier!.drop(data, const Offset(9999, 9999));

      expect(receivedDetails, isNull);
    });
  });

  group('TideDragSource', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => const TideExternalDragScope(
                  child: TideDragSource(
                    data: TideExternalDragData(
                      subject: 'Draggable',
                      duration: Duration(hours: 1),
                    ),
                    child: Text('Drag me'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Drag me'), findsOneWidget);
    });

    testWidgets('renders child when disabled', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: TideDragSource(
            data: TideExternalDragData(
              subject: 'Draggable',
              duration: Duration(hours: 1),
            ),
            enabled: false,
            child: Text('Disabled'),
          ),
        ),
      );

      expect(find.text('Disabled'), findsOneWidget);
    });
  });
}
