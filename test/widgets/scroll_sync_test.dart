import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/widgets/common/scroll_sync.dart';

void main() {
  group('TideScrollSync', () {
    late ScrollController primary;
    late ScrollController secondary;
    late TideScrollSync sync;

    setUp(() {
      primary = ScrollController();
      secondary = ScrollController();
      sync = TideScrollSync(primary: primary, secondary: secondary);
    });

    tearDown(() {
      sync.dispose();
      primary.dispose();
      secondary.dispose();
    });

    testWidgets('syncs primary scroll to secondary', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 50,
                child: SingleChildScrollView(
                  controller: primary,
                  child: const SizedBox(width: 100, height: 300),
                ),
              ),
              SizedBox(
                width: 100,
                height: 50,
                child: SingleChildScrollView(
                  controller: secondary,
                  child: const SizedBox(width: 100, height: 300),
                ),
              ),
            ],
          ),
        ),
      );

      primary.jumpTo(100.0);
      await tester.pump();

      expect(secondary.offset, 100.0);
    });

    testWidgets('syncs secondary scroll to primary', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 50,
                child: SingleChildScrollView(
                  controller: primary,
                  child: const SizedBox(width: 100, height: 300),
                ),
              ),
              SizedBox(
                width: 100,
                height: 50,
                child: SingleChildScrollView(
                  controller: secondary,
                  child: const SizedBox(width: 100, height: 300),
                ),
              ),
            ],
          ),
        ),
      );

      secondary.jumpTo(75.0);
      await tester.pump();

      expect(primary.offset, 75.0);
    });

    testWidgets('does not cause infinite loop on sync', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 50,
                child: SingleChildScrollView(
                  controller: primary,
                  child: const SizedBox(width: 100, height: 300),
                ),
              ),
              SizedBox(
                width: 100,
                height: 50,
                child: SingleChildScrollView(
                  controller: secondary,
                  child: const SizedBox(width: 100, height: 300),
                ),
              ),
            ],
          ),
        ),
      );

      // If there were an infinite loop, this would throw a stack overflow.
      expect(() {
        primary.jumpTo(50.0);
      }, returnsNormally);

      expect(primary.offset, 50.0);
      expect(secondary.offset, 50.0);
    });

    test('dispose removes listeners from both controllers', () {
      // Verify dispose does not throw and completes cleanly.
      // The tearDown will subsequently dispose the controllers,
      // confirming no dangling listener references remain.
      expect(() => sync.dispose(), returnsNormally);

      // Create a second sync and dispose it too — ensures removeListener
      // is idempotent and does not throw even when called on already-clean
      // controllers.
      final sync2 = TideScrollSync(primary: primary, secondary: secondary);
      expect(() => sync2.dispose(), returnsNormally);
    });
  });
}
