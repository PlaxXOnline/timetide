import 'dart:ui' show Canvas, Color, PictureRecorder, Size;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/time_region.dart';
import 'package:timetide/src/rendering/time_region_painter.dart';

Canvas _recordingCanvas() {
  final recorder = PictureRecorder();
  return Canvas(recorder);
}

void main() {
  group('TidePositionedRegion', () {
    test('can be constructed', () {
      const region = TidePositionedRegion(
        type: TimeRegionType.blocked,
        top: 100,
        height: 200,
      );
      expect(region.type, TimeRegionType.blocked);
      expect(region.top, 100);
      expect(region.height, 200);
      expect(region.color, isNull);
      expect(region.text, isNull);
    });

    test('supports optional color and text', () {
      const region = TidePositionedRegion(
        type: TimeRegionType.highlight,
        top: 50,
        height: 100,
        color: Color(0xFF2196F3),
        text: 'Lunch Break',
      );
      expect(region.color, const Color(0xFF2196F3));
      expect(region.text, 'Lunch Break');
    });

    test('equality works by value', () {
      const a = TidePositionedRegion(
        type: TimeRegionType.blocked,
        top: 100,
        height: 200,
        color: Color(0xFF000000),
      );
      const b = TidePositionedRegion(
        type: TimeRegionType.blocked,
        top: 100,
        height: 200,
        color: Color(0xFF000000),
      );
      const c = TidePositionedRegion(
        type: TimeRegionType.highlight,
        top: 100,
        height: 200,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('TideTimeRegionPainter', () {
    test('can be constructed with empty regions', () {
      const painter = TideTimeRegionPainter(regions: []);
      expect(painter.regions, isEmpty);
    });

    test('can be constructed with regions', () {
      const painter = TideTimeRegionPainter(
        regions: [
          TidePositionedRegion(
            type: TimeRegionType.blocked,
            top: 0,
            height: 100,
          ),
          TidePositionedRegion(
            type: TimeRegionType.highlight,
            top: 200,
            height: 50,
            color: Color(0xFF2196F3),
          ),
        ],
      );
      expect(painter.regions.length, 2);
    });

    group('shouldRepaint', () {
      test('returns false for identical regions', () {
        const a = TideTimeRegionPainter(
          regions: [
            TidePositionedRegion(
              type: TimeRegionType.blocked,
              top: 0,
              height: 100,
            ),
          ],
        );
        const b = TideTimeRegionPainter(
          regions: [
            TidePositionedRegion(
              type: TimeRegionType.blocked,
              top: 0,
              height: 100,
            ),
          ],
        );
        expect(a.shouldRepaint(b), isFalse);
      });

      test('returns true when region count differs', () {
        const a = TideTimeRegionPainter(regions: []);
        const b = TideTimeRegionPainter(
          regions: [
            TidePositionedRegion(
              type: TimeRegionType.blocked,
              top: 0,
              height: 100,
            ),
          ],
        );
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when region type differs', () {
        const a = TideTimeRegionPainter(
          regions: [
            TidePositionedRegion(
              type: TimeRegionType.blocked,
              top: 0,
              height: 100,
            ),
          ],
        );
        const b = TideTimeRegionPainter(
          regions: [
            TidePositionedRegion(
              type: TimeRegionType.highlight,
              top: 0,
              height: 100,
            ),
          ],
        );
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when region position differs', () {
        const a = TideTimeRegionPainter(
          regions: [
            TidePositionedRegion(
              type: TimeRegionType.blocked,
              top: 0,
              height: 100,
            ),
          ],
        );
        const b = TideTimeRegionPainter(
          regions: [
            TidePositionedRegion(
              type: TimeRegionType.blocked,
              top: 50,
              height: 100,
            ),
          ],
        );
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when defaultHighlightColor changes', () {
        const a = TideTimeRegionPainter(
          regions: [],
          defaultHighlightColor: Color(0x332196F3),
        );
        const b = TideTimeRegionPainter(
          regions: [],
          defaultHighlightColor: Color(0xFF000000),
        );
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when defaultBlockedColor changes', () {
        const a = TideTimeRegionPainter(
          regions: [],
          defaultBlockedColor: Color(0xFF9E9E9E),
        );
        const b = TideTimeRegionPainter(
          regions: [],
          defaultBlockedColor: Color(0xFF000000),
        );
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when textStyle changes', () {
        const a = TideTimeRegionPainter(
          regions: [],
          textStyle: TextStyle(fontSize: 12),
        );
        const b = TideTimeRegionPainter(
          regions: [],
          textStyle: TextStyle(fontSize: 14),
        );
        expect(a.shouldRepaint(b), isTrue);
      });
    });

    group('paint', () {
      test('does not throw with empty regions', () {
        const painter = TideTimeRegionPainter(regions: []);
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(400, 1440)),
          returnsNormally,
        );
      });

      test('does not throw with blocked region', () {
        const painter = TideTimeRegionPainter(
          regions: [
            TidePositionedRegion(
              type: TimeRegionType.blocked,
              top: 100,
              height: 200,
            ),
          ],
        );
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(400, 1440)),
          returnsNormally,
        );
      });

      test('does not throw with highlight region', () {
        const painter = TideTimeRegionPainter(
          regions: [
            TidePositionedRegion(
              type: TimeRegionType.highlight,
              top: 50,
              height: 100,
              color: Color(0x332196F3),
            ),
          ],
        );
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(400, 1440)),
          returnsNormally,
        );
      });

      test('does not throw with nonWorking region', () {
        const painter = TideTimeRegionPainter(
          regions: [
            TidePositionedRegion(
              type: TimeRegionType.nonWorking,
              top: 0,
              height: 540,
            ),
          ],
        );
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(400, 1440)),
          returnsNormally,
        );
      });

      test('does not throw with working region (no-op)', () {
        const painter = TideTimeRegionPainter(
          regions: [
            TidePositionedRegion(
              type: TimeRegionType.working,
              top: 540,
              height: 480,
            ),
          ],
        );
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(400, 1440)),
          returnsNormally,
        );
      });

      test('does not throw with custom region (skipped)', () {
        const painter = TideTimeRegionPainter(
          regions: [
            TidePositionedRegion(
              type: TimeRegionType.custom,
              top: 100,
              height: 100,
            ),
          ],
        );
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(400, 1440)),
          returnsNormally,
        );
      });

      test('does not throw with text label', () {
        const painter = TideTimeRegionPainter(
          regions: [
            TidePositionedRegion(
              type: TimeRegionType.highlight,
              top: 100,
              height: 100,
              text: 'Lunch Break',
            ),
          ],
          textStyle: TextStyle(fontSize: 12, color: Color(0xFF000000)),
        );
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(400, 1440)),
          returnsNormally,
        );
      });

      test('does not throw with all region types at once', () {
        const painter = TideTimeRegionPainter(
          regions: [
            TidePositionedRegion(
              type: TimeRegionType.nonWorking,
              top: 0,
              height: 100,
            ),
            TidePositionedRegion(
              type: TimeRegionType.working,
              top: 100,
              height: 200,
            ),
            TidePositionedRegion(
              type: TimeRegionType.blocked,
              top: 300,
              height: 100,
              color: Color(0xFF9E9E9E),
            ),
            TidePositionedRegion(
              type: TimeRegionType.highlight,
              top: 400,
              height: 50,
              color: Color(0x332196F3),
              text: 'Meeting',
            ),
            TidePositionedRegion(
              type: TimeRegionType.custom,
              top: 450,
              height: 50,
            ),
          ],
          textStyle: TextStyle(fontSize: 12, color: Color(0xFF000000)),
        );
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(400, 1440)),
          returnsNormally,
        );
      });

      test('does not draw text when textStyle is null', () {
        const painter = TideTimeRegionPainter(
          regions: [
            TidePositionedRegion(
              type: TimeRegionType.highlight,
              top: 100,
              height: 100,
              text: 'Should not throw',
            ),
          ],
          // textStyle intentionally null
        );
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(400, 1440)),
          returnsNormally,
        );
      });
    });
  });
}
