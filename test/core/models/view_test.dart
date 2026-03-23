import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/view.dart';

void main() {
  group('TideView', () {
    test('has exactly 13 values', () {
      expect(TideView.values.length, 13);
    });

    test('contains all expected values', () {
      expect(TideView.values, containsAll([
        TideView.day,
        TideView.week,
        TideView.workWeek,
        TideView.month,
        TideView.schedule,
        TideView.timelineDay,
        TideView.timelineWeek,
        TideView.timelineWorkWeek,
        TideView.timelineMonth,
        TideView.multiWeek,
        TideView.year,
        TideView.resourceDay,
        TideView.resourceWeek,
      ]));
    });
  });
}
