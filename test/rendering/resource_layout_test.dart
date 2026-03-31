import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/resource.dart';
import 'package:timetide/src/rendering/resource_layout.dart';

void main() {
  // Shared helpers --------------------------------------------------------

  TideResource makeResource(String id, {String? groupId}) {
    return TideResource(
      id: id,
      displayName: 'Resource $id',
      color: const Color(0xFF0000FF),
      groupId: groupId,
    );
  }

  const width = 800.0;
  const height = 600.0;

  // -- TideResourceBounds -------------------------------------------------

  group('TideResourceBounds', () {
    test('equality and hashCode', () {
      const a = TideResourceBounds(left: 0, top: 0, width: 100, height: 50);
      const b = TideResourceBounds(left: 0, top: 0, width: 100, height: 50);
      const c = TideResourceBounds(left: 1, top: 0, width: 100, height: 50);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString contains field values', () {
      const bounds =
          TideResourceBounds(left: 1.0, top: 2.0, width: 3.0, height: 4.0);
      expect(bounds.toString(), contains('1.0'));
      expect(bounds.toString(), contains('4.0'));
    });
  });

  // -- Empty list ---------------------------------------------------------

  group('Empty resources', () {
    test('returns empty list for all modes', () {
      for (final mode in TideResourceViewMode.values) {
        final results = TideResourceLayout.layout(
          resources: [],
          mode: mode,
          availableWidth: width,
          availableHeight: height,
        );
        expect(results, isEmpty, reason: 'mode: $mode');
      }
    });
  });

  // -- Rows mode ----------------------------------------------------------

  group('rows mode', () {
    test('single resource gets full height minus header', () {
      final resources = [makeResource('a')];
      final results = TideResourceLayout.layout(
        resources: resources,
        mode: TideResourceViewMode.rows,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.length, 1);
      final r = results.first;
      // Content area starts after header width (default 120).
      expect(r.bounds.left, 120.0);
      expect(r.bounds.top, 0.0);
      expect(r.bounds.width, width - 120.0);
      expect(r.bounds.height, height);
      // Header
      expect(r.headerBounds.left, 0.0);
      expect(r.headerBounds.width, 120.0);
      expect(r.headerBounds.height, height);
    });

    test('three resources divide height equally', () {
      final resources = [makeResource('a'), makeResource('b'), makeResource('c')];
      final results = TideResourceLayout.layout(
        resources: resources,
        mode: TideResourceViewMode.rows,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.length, 3);
      const rowH = height / 3;
      for (var i = 0; i < 3; i++) {
        expect(results[i].bounds.top, closeTo(i * rowH, 0.01));
        expect(results[i].bounds.height, closeTo(rowH, 0.01));
      }
    });

    test('fixedRowHeight overrides auto-calculation', () {
      final resources = [makeResource('a'), makeResource('b')];
      final results = TideResourceLayout.layout(
        resources: resources,
        mode: TideResourceViewMode.rows,
        availableWidth: width,
        availableHeight: height,
        fixedRowHeight: 80.0,
      );

      for (final r in results) {
        expect(r.bounds.height, 80.0);
      }
      // Second row starts at 80.
      expect(results[1].bounds.top, 80.0);
    });

    test('custom resourceHeaderWidth', () {
      final resources = [makeResource('a')];
      final results = TideResourceLayout.layout(
        resources: resources,
        mode: TideResourceViewMode.rows,
        availableWidth: width,
        availableHeight: height,
        resourceHeaderWidth: 200.0,
      );

      expect(results.first.headerBounds.width, 200.0);
      expect(results.first.bounds.left, 200.0);
      expect(results.first.bounds.width, width - 200.0);
    });
  });

  // -- Columns mode -------------------------------------------------------

  group('columns mode', () {
    test('single resource gets full width', () {
      final resources = [makeResource('a')];
      final results = TideResourceLayout.layout(
        resources: resources,
        mode: TideResourceViewMode.columns,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.length, 1);
      final r = results.first;
      expect(r.bounds.left, 0.0);
      // Content starts below column header (default 40).
      expect(r.bounds.top, 40.0);
      expect(r.bounds.width, width);
      expect(r.bounds.height, height - 40.0);
      // Header on top.
      expect(r.headerBounds.left, 0.0);
      expect(r.headerBounds.top, 0.0);
      expect(r.headerBounds.width, width);
      expect(r.headerBounds.height, 40.0);
    });

    test('three resources divide width equally', () {
      final resources = [makeResource('a'), makeResource('b'), makeResource('c')];
      final results = TideResourceLayout.layout(
        resources: resources,
        mode: TideResourceViewMode.columns,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.length, 3);
      const colW = width / 3;
      for (var i = 0; i < 3; i++) {
        expect(results[i].bounds.left, closeTo(i * colW, 0.01));
        expect(results[i].bounds.width, closeTo(colW, 0.01));
      }
    });

    test('fixedColumnWidth overrides auto-calculation', () {
      final resources = [makeResource('a'), makeResource('b')];
      final results = TideResourceLayout.layout(
        resources: resources,
        mode: TideResourceViewMode.columns,
        availableWidth: width,
        availableHeight: height,
        fixedColumnWidth: 150.0,
      );

      for (final r in results) {
        expect(r.bounds.width, 150.0);
      }
      expect(results[1].bounds.left, 150.0);
    });
  });

  // -- Grouped mode -------------------------------------------------------

  group('grouped mode', () {
    test('creates group headers and resource rows', () {
      final resources = [
        makeResource('a', groupId: 'g1'),
        makeResource('b', groupId: 'g1'),
        makeResource('c', groupId: 'g2'),
      ];
      final results = TideResourceLayout.layout(
        resources: resources,
        mode: TideResourceViewMode.grouped,
        availableWidth: width,
        availableHeight: height,
      );

      // 2 group headers + 3 resource rows.
      expect(results.length, 5);

      final headers = results.where((r) => r.isGroupHeader).toList();
      expect(headers.length, 2);
      expect(headers[0].groupId, 'g1');
      expect(headers[1].groupId, 'g2');

      // Group headers span full width.
      for (final h in headers) {
        expect(h.bounds.width, width);
      }
    });

    test('resources without groupId are grouped together', () {
      final resources = [
        makeResource('a'),
        makeResource('b'),
      ];
      final results = TideResourceLayout.layout(
        resources: resources,
        mode: TideResourceViewMode.grouped,
        availableWidth: width,
        availableHeight: height,
      );

      final headers = results.where((r) => r.isGroupHeader).toList();
      expect(headers.length, 1);
      expect(headers.first.groupId, isNull);
      expect(headers.first.groupDisplayName, 'Ungrouped');
    });

    test('group header height is configurable', () {
      final resources = [makeResource('a', groupId: 'g1')];
      final results = TideResourceLayout.layout(
        resources: resources,
        mode: TideResourceViewMode.grouped,
        availableWidth: width,
        availableHeight: height,
        groupHeaderHeight: 50.0,
      );

      final header = results.firstWhere((r) => r.isGroupHeader);
      expect(header.bounds.height, 50.0);
    });

    test('resource rows start after group header', () {
      final resources = [
        makeResource('a', groupId: 'g1'),
      ];
      final results = TideResourceLayout.layout(
        resources: resources,
        mode: TideResourceViewMode.grouped,
        availableWidth: width,
        availableHeight: height,
        groupHeaderHeight: 32.0,
      );

      final resourceRow =
          results.firstWhere((r) => !r.isGroupHeader);
      expect(resourceRow.bounds.top, 32.0);
    });
  });

  // -- Stacked mode -------------------------------------------------------

  group('stacked mode', () {
    test('all resources share the full container', () {
      final resources = [makeResource('a'), makeResource('b'), makeResource('c')];
      final results = TideResourceLayout.layout(
        resources: resources,
        mode: TideResourceViewMode.stacked,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.length, 3);
      for (final r in results) {
        expect(r.bounds.left, 0.0);
        expect(r.bounds.top, 0.0);
        expect(r.bounds.width, width);
        expect(r.bounds.height, height);
      }
    });

    test('stacked headers have zero height', () {
      final resources = [makeResource('a')];
      final results = TideResourceLayout.layout(
        resources: resources,
        mode: TideResourceViewMode.stacked,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.first.headerBounds.height, 0.0);
    });
  });

  // -- TideResourceLayoutResult -------------------------------------------

  group('TideResourceLayoutResult', () {
    test('equality and hashCode', () {
      final resource = makeResource('a');
      const bounds =
          TideResourceBounds(left: 0, top: 0, width: 100, height: 50);
      const hBounds =
          TideResourceBounds(left: 0, top: 0, width: 50, height: 50);

      final a = TideResourceLayoutResult(
        resource: resource,
        bounds: bounds,
        headerBounds: hBounds,
      );
      final b = TideResourceLayoutResult(
        resource: resource,
        bounds: bounds,
        headerBounds: hBounds,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
