
import 'package:flutter/widgets.dart' show Axis;
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/interaction/drag_drop/time_axis.dart';

void main() {
  group('TideTimeAxis', () {
    group('vertical', () {
      test('timeToPixel computes correct Y for 09:30 with startHour=0, hourHeight=60', () {
        final axis = TideTimeAxis.vertical(
          date: DateTime(2024, 1, 1),
          startHour: 0,
          hourHeight: 60,
        );
        expect(axis.timeToPixel(DateTime(2024, 1, 1, 9, 30)), 570.0);
      });

      test('pixelToTime computes correct time for Y=570 with startHour=0, hourHeight=60', () {
        final axis = TideTimeAxis.vertical(
          date: DateTime(2024, 1, 1),
          startHour: 0,
          hourHeight: 60,
        );
        expect(axis.pixelToTime(570.0), DateTime(2024, 1, 1, 9, 30));
      });

      test('round-trip: pixelToTime(timeToPixel(t)) == t', () {
        final axis = TideTimeAxis.vertical(
          date: DateTime(2024, 1, 1),
          startHour: 0,
          hourHeight: 60,
        );
        final times = [
          DateTime(2024, 1, 1, 0, 0),
          DateTime(2024, 1, 1, 8, 0),
          DateTime(2024, 1, 1, 12, 30),
          DateTime(2024, 1, 1, 17, 45),
          DateTime(2024, 1, 1, 23, 0),
        ];
        for (final t in times) {
          final pixel = axis.timeToPixel(t);
          final roundTrip = axis.pixelToTime(pixel);
          expect(roundTrip, t, reason: 'Round-trip failed for $t');
        }
      });

      test('handles fractional startHour', () {
        final axis = TideTimeAxis.vertical(
          date: DateTime(2024, 1, 1),
          startHour: 6.5,
          hourHeight: 60,
        );
        // At Y=0, time should be 06:30
        expect(axis.pixelToTime(0), DateTime(2024, 1, 1, 6, 30));
        // 06:30 should map to Y=0
        expect(axis.timeToPixel(DateTime(2024, 1, 1, 6, 30)), 0.0);
      });

      test('midnight is Y=0 when startHour=0', () {
        final axis = TideTimeAxis.vertical(
          date: DateTime(2024, 1, 1),
          startHour: 0,
          hourHeight: 60,
        );
        expect(axis.pixelToTime(0), DateTime(2024, 1, 1, 0, 0));
        expect(axis.timeToPixel(DateTime(2024, 1, 1, 0, 0)), 0.0);
      });

      test('23:59 maps correctly', () {
        final axis = TideTimeAxis.vertical(
          date: DateTime(2024, 1, 1),
          startHour: 0,
          hourHeight: 60,
        );
        final t = DateTime(2024, 1, 1, 23, 0);
        expect(axis.timeToPixel(t), 1380.0);
        expect(axis.pixelToTime(1380.0), t);
      });
    });

    group('horizontal', () {
      test('timeToPixel computes correct X for 09:30 with startHour=0, hourWidth=60', () {
        final axis = TideTimeAxis.horizontal(
          date: DateTime(2024, 1, 1),
          startHour: 0,
          hourWidth: 60,
        );
        expect(axis.timeToPixel(DateTime(2024, 1, 1, 9, 30)), 570.0);
      });

      test('pixelToTime computes correct time for X=570 with startHour=0, hourWidth=60', () {
        final axis = TideTimeAxis.horizontal(
          date: DateTime(2024, 1, 1),
          startHour: 0,
          hourWidth: 60,
        );
        expect(axis.pixelToTime(570.0), DateTime(2024, 1, 1, 9, 30));
      });

      test('round-trip: pixelToTime(timeToPixel(t)) == t', () {
        final axis = TideTimeAxis.horizontal(
          date: DateTime(2024, 1, 1),
          startHour: 0,
          hourWidth: 120,
        );
        final times = [
          DateTime(2024, 1, 1, 0, 0),
          DateTime(2024, 1, 1, 10, 15),
          DateTime(2024, 1, 1, 18, 45),
        ];
        for (final t in times) {
          final pixel = axis.timeToPixel(t);
          final roundTrip = axis.pixelToTime(pixel);
          expect(roundTrip, t, reason: 'Round-trip failed for $t');
        }
      });
    });

    group('custom functions', () {
      test('accepts arbitrary pixelToTime and timeToPixel', () {
        // Custom axis that always returns a fixed time/pixel.
        final axis = TideTimeAxis(
          pixelToTime: (_) => DateTime(2024, 6, 15, 12, 0),
          timeToPixel: (_) => 42.0,
        );
        expect(axis.pixelToTime(999), DateTime(2024, 6, 15, 12, 0));
        expect(axis.timeToPixel(DateTime(2024, 1, 1)), 42.0);
      });

      test('default direction is Axis.vertical', () {
        final axis = TideTimeAxis(
          pixelToTime: (_) => DateTime(2024, 1, 1),
          timeToPixel: (_) => 0.0,
        );
        expect(axis.direction, Axis.vertical);
      });
    });

    group('direction', () {
      test('vertical factory sets direction to Axis.vertical', () {
        final axis = TideTimeAxis.vertical(
          date: DateTime(2024, 1, 1),
          startHour: 0,
          hourHeight: 60,
        );
        expect(axis.direction, Axis.vertical);
      });

      test('horizontal factory sets direction to Axis.horizontal', () {
        final axis = TideTimeAxis.horizontal(
          date: DateTime(2024, 1, 1),
          startHour: 0,
          hourWidth: 60,
        );
        expect(axis.direction, Axis.horizontal);
      });
    });

    group('offsetToPixel', () {
      test('vertical axis returns dy component', () {
        final axis = TideTimeAxis.vertical(
          date: DateTime(2024, 1, 1),
          startHour: 0,
          hourHeight: 60,
        );
        const offset = Offset(100.0, 250.0);
        expect(axis.offsetToPixel(offset), 250.0);
      });

      test('horizontal axis returns dx component', () {
        final axis = TideTimeAxis.horizontal(
          date: DateTime(2024, 1, 1),
          startHour: 0,
          hourWidth: 60,
        );
        const offset = Offset(100.0, 250.0);
        expect(axis.offsetToPixel(offset), 100.0);
      });
    });

    group('deltaToPixel', () {
      test('vertical axis returns dy component of delta', () {
        final axis = TideTimeAxis.vertical(
          date: DateTime(2024, 1, 1),
          startHour: 0,
          hourHeight: 60,
        );
        const delta = Offset(5.0, 12.0);
        expect(axis.deltaToPixel(delta), 12.0);
      });

      test('horizontal axis returns dx component of delta', () {
        final axis = TideTimeAxis.horizontal(
          date: DateTime(2024, 1, 1),
          startHour: 0,
          hourWidth: 60,
        );
        const delta = Offset(5.0, 12.0);
        expect(axis.deltaToPixel(delta), 5.0);
      });
    });
  });
}
