import 'dart:ui' show Canvas, Color, PictureRecorder, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/rendering/time_slot_painter.dart';

TideTimeSlotPainter _createPainter({
  double startHour = 0,
  double endHour = 24,
  Duration timeSlotInterval = const Duration(minutes: 30),
  double hourHeight = 60,
  Color timeSlotBorderColor = const Color(0xFFEEEEEE),
  double timeSlotBorderWidth = 0.5,
  Color workingHoursColor = const Color(0xFFFFFFFF),
  Color nonWorkingHoursColor = const Color(0xFFFAFAFA),
  double? workingHoursStart,
  double? workingHoursEnd,
}) {
  return TideTimeSlotPainter(
    startHour: startHour,
    endHour: endHour,
    timeSlotInterval: timeSlotInterval,
    hourHeight: hourHeight,
    timeSlotBorderColor: timeSlotBorderColor,
    timeSlotBorderWidth: timeSlotBorderWidth,
    workingHoursColor: workingHoursColor,
    nonWorkingHoursColor: nonWorkingHoursColor,
    workingHoursStart: workingHoursStart,
    workingHoursEnd: workingHoursEnd,
  );
}

Canvas _recordingCanvas() {
  final recorder = PictureRecorder();
  return Canvas(recorder);
}

void main() {
  group('TideTimeSlotPainter', () {
    test('can be constructed with required parameters', () {
      final painter = _createPainter();
      expect(painter.startHour, 0);
      expect(painter.endHour, 24);
      expect(painter.hourHeight, 60);
      expect(painter.workingHoursStart, isNull);
      expect(painter.workingHoursEnd, isNull);
    });

    test('can be constructed with working hours', () {
      final painter = _createPainter(
        workingHoursStart: 9.0,
        workingHoursEnd: 17.0,
      );
      expect(painter.workingHoursStart, 9.0);
      expect(painter.workingHoursEnd, 17.0);
    });

    test('hourToY converts fractional hour to pixel offset', () {
      final painter = _createPainter(startHour: 6, hourHeight: 60);
      expect(painter.hourToY(6), 0);
      expect(painter.hourToY(7), 60);
      expect(painter.hourToY(6.5), 30);
      expect(painter.hourToY(12), 360);
    });

    group('shouldRepaint', () {
      test('returns false for identical parameters', () {
        final a = _createPainter();
        final b = _createPainter();
        expect(a.shouldRepaint(b), isFalse);
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

      test('returns true when timeSlotInterval changes', () {
        final a = _createPainter(
          timeSlotInterval: const Duration(minutes: 30),
        );
        final b = _createPainter(
          timeSlotInterval: const Duration(minutes: 15),
        );
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when hourHeight changes', () {
        final a = _createPainter(hourHeight: 60);
        final b = _createPainter(hourHeight: 80);
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when border color changes', () {
        final a = _createPainter(
          timeSlotBorderColor: const Color(0xFFEEEEEE),
        );
        final b = _createPainter(
          timeSlotBorderColor: const Color(0xFF000000),
        );
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when border width changes', () {
        final a = _createPainter(timeSlotBorderWidth: 0.5);
        final b = _createPainter(timeSlotBorderWidth: 1.0);
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when working hours colors change', () {
        final a = _createPainter(
          workingHoursColor: const Color(0xFFFFFFFF),
        );
        final b = _createPainter(
          workingHoursColor: const Color(0xFF000000),
        );
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when non-working hours colors change', () {
        final a = _createPainter(
          nonWorkingHoursColor: const Color(0xFFFAFAFA),
        );
        final b = _createPainter(
          nonWorkingHoursColor: const Color(0xFF000000),
        );
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when workingHoursStart changes', () {
        final a = _createPainter(workingHoursStart: 9.0);
        final b = _createPainter(workingHoursStart: 8.0);
        expect(a.shouldRepaint(b), isTrue);
      });

      test('returns true when workingHoursEnd changes', () {
        final a = _createPainter(workingHoursEnd: 17.0);
        final b = _createPainter(workingHoursEnd: 18.0);
        expect(a.shouldRepaint(b), isTrue);
      });
    });

    group('paint', () {
      test('does not throw with standard parameters', () {
        final painter = _createPainter(
          workingHoursStart: 9.0,
          workingHoursEnd: 17.0,
        );
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(400, 1440)),
          returnsNormally,
        );
      });

      test('does not throw without working hours', () {
        final painter = _createPainter();
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(400, 1440)),
          returnsNormally,
        );
      });

      test('does not throw with zero-width canvas', () {
        final painter = _createPainter();
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(0, 1440)),
          returnsNormally,
        );
      });

      test('does not throw with partial day range', () {
        final painter = _createPainter(
          startHour: 8,
          endHour: 18,
          workingHoursStart: 9.0,
          workingHoursEnd: 17.0,
        );
        final canvas = _recordingCanvas();
        expect(
          () => painter.paint(canvas, const Size(400, 600)),
          returnsNormally,
        );
      });

      test('handles 15-minute intervals', () {
        final painter = _createPainter(
          timeSlotInterval: const Duration(minutes: 15),
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
