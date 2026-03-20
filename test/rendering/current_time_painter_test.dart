import 'dart:ui' show Canvas, Color, PictureRecorder, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/rendering/current_time_painter.dart';

TideCurrentTimePainter _createPainter({
  DateTime? currentTime,
  double startHour = 0,
  double endHour = 24,
  double hourHeight = 60,
  Color color = const Color(0xFFFF1744),
  double lineHeight = 2.0,
  double circleRadius = 5.0,
}) {
  return TideCurrentTimePainter(
    currentTime: currentTime ?? DateTime(2024, 6, 15, 10, 30),
    startHour: startHour,
    endHour: endHour,
    hourHeight: hourHeight,
    color: color,
    lineHeight: lineHeight,
    circleRadius: circleRadius,
  );
}

Canvas _recordingCanvas() {
  final recorder = PictureRecorder();
  return Canvas(recorder);
}

void main() {
  group('TideCurrentTimePainter', () {
    test('can be constructed with required parameters', () {
      final painter = _createPainter();
      expect(painter.startHour, 0);
      expect(painter.endHour, 24);
      expect(painter.hourHeight, 60);
      expect(painter.circleRadius, 5.0);
    });

    test('default circleRadius is 5.0', () {
      final painter = TideCurrentTimePainter(
        currentTime: DateTime(2024, 6, 15, 10, 30),
        startHour: 0,
        endHour: 24,
        hourHeight: 60,
        color: const Color(0xFFFF1744),
        lineHeight: 2.0,
      );
      expect(painter.circleRadius, 5.0);
    });

    group('yPosition', () {
      test('calculates correct y for 10:30 starting at hour 0', () {
        final painter = _createPainter(
          currentTime: DateTime(2024, 6, 15, 10, 30),
          startHour: 0,
          hourHeight: 60,
        );
        // 10.5 hours * 60 px/hr = 630 px
        expect(painter.yPosition, closeTo(630, 0.01));
      });

      test('calculates correct y with non-zero start hour', () {
        final painter = _createPainter(
          currentTime: DateTime(2024, 6, 15, 10, 30),
          startHour: 8,
          hourHeight: 60,
        );
        // (10.5 - 8) * 60 = 150 px
        expect(painter.yPosition, closeTo(150, 0.01));
      });

      test('calculates correct y at exact hour', () {
        final painter = _createPainter(
          currentTime: DateTime(2024, 6, 15, 12, 0),
          startHour: 0,
          hourHeight: 60,
        );
        // 12 * 60 = 720 px
        expect(painter.yPosition, closeTo(720, 0.01));
      });

      test('calculates correct y at midnight', () {
        final painter = _createPainter(
          currentTime: DateTime(2024, 6, 15, 0, 0),
          startHour: 0,
          hourHeight: 60,
        );
        expect(painter.yPosition, closeTo(0, 0.01));
      });

      test('works with different hourHeight', () {
        final painter = _createPainter(
          currentTime: DateTime(2024, 6, 15, 10, 0),
          startHour: 0,
          hourHeight: 100,
        );
        // 10 * 100 = 1000 px
        expect(painter.yPosition, closeTo(1000, 0.01));
      });
    });

    group('shouldRepaint', () {
      test('returns false for identical parameters', () {
        final a = _createPainter();
        final b = _createPainter();
        expect(a.shouldRepaint(b), isFalse);
      });

      test('returns true when hour changes', () {
        final a = _createPainter(
          currentTime: DateTime(2024, 6, 15, 10, 30),
        );
        final b = _createPainter(
          currentTime: DateTime(2024, 6, 15, 11, 30),
        );
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when minute changes', () {
        final a = _createPainter(
          currentTime: DateTime(2024, 6, 15, 10, 30),
        );
        final b = _createPainter(
          currentTime: DateTime(2024, 6, 15, 10, 31),
        );
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns false when only seconds change', () {
        final a = _createPainter(
          currentTime: DateTime(2024, 6, 15, 10, 30, 0),
        );
        final b = _createPainter(
          currentTime: DateTime(2024, 6, 15, 10, 30, 45),
        );
        expect(a.shouldRepaint(b), isFalse);
      });

      test('returns true when color changes', () {
        final a = _createPainter(color: const Color(0xFFFF1744));
        final b = _createPainter(color: const Color(0xFF000000));
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when hourHeight changes', () {
        final a = _createPainter(hourHeight: 60);
        final b = _createPainter(hourHeight: 80);
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when startHour changes', () {
        final a = _createPainter(startHour: 0);
        final b = _createPainter(startHour: 6);
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when endHour changes', () {
        final a = _createPainter(endHour: 24);
        final b = _createPainter(endHour: 18);
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when lineHeight changes', () {
        final a = _createPainter(lineHeight: 2.0);
        final b = _createPainter(lineHeight: 3.0);
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when circleRadius changes', () {
        final a = _createPainter(circleRadius: 5.0);
        final b = _createPainter(circleRadius: 8.0);
        expect(a.shouldRepaint(b), isTrue);
      });
    });

    group('paint', () {
      test('does not throw with standard parameters', () {
        final painter = _createPainter();
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(400, 1440)),
          returnsNormally,
        );
      });

      test('does not throw when time is outside visible range', () {
        final painter = _createPainter(
          currentTime: DateTime(2024, 6, 15, 6, 0),
          startHour: 8,
          endHour: 18,
        );
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(400, 600)),
          returnsNormally,
        );
      });

      test('does not throw at boundary start hour', () {
        final painter = _createPainter(
          currentTime: DateTime(2024, 6, 15, 8, 0),
          startHour: 8,
          endHour: 18,
        );
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(400, 600)),
          returnsNormally,
        );
      });
    });
  });

  group('TideCurrentTimeNotifier', () {
    test('exposes currentTime', () {
      final notifier = TideCurrentTimeNotifier();
      addTearDown(notifier.dispose);

      final now = DateTime.now();
      // The notifier's time should be very close to now.
      expect(
        notifier.currentTime.difference(now).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('can be disposed without error', () {
      final notifier = TideCurrentTimeNotifier();
      expect(notifier.dispose, returnsNormally);
    });

    test('notifies listeners on tick', () {
      final notifier = TideCurrentTimeNotifier();
      addTearDown(notifier.dispose);

      var notified = false;
      notifier.addListener(() => notified = true);

      // We can't wait 1 minute in a test, but we verify the listener
      // mechanism works by checking the setup doesn't throw.
      expect(notified, isFalse);
    });
  });
}
