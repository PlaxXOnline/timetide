import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/widgets/context_menu/tide_context_menu.dart';

Widget _app(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: TideTheme(
      data: const TideThemeData(),
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (_) => Center(child: child),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('TideContextMenu', () {
    testWidgets('shows context menu on long press', (tester) async {
      String? tappedItem;

      await tester.pumpWidget(_app(
        TideContextMenu(
          items: [
            TideContextMenuItem(
              label: 'Edit',
              onTap: () => tappedItem = 'edit',
            ),
            TideContextMenuItem(
              label: 'Delete',
              onTap: () => tappedItem = 'delete',
            ),
          ],
          child: const SizedBox(width: 100, height: 100),
        ),
      ));

      // Long press to open menu.
      await tester.longPress(find.byType(TideContextMenu));
      await tester.pumpAndSettle();

      // Menu items should be visible.
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap an item.
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(tappedItem, 'edit');
    });

    testWidgets('dismisses on outside tap', (tester) async {
      await tester.pumpWidget(_app(
        TideContextMenu(
          items: [
            TideContextMenuItem(label: 'Action', onTap: () {}),
          ],
          child: const SizedBox(width: 100, height: 100),
        ),
      ));

      // Open menu via long press.
      await tester.longPress(find.byType(TideContextMenu));
      await tester.pumpAndSettle();
      expect(find.text('Action'), findsOneWidget);

      // Tap outside (top-left corner, away from center and menu).
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('Action'), findsNothing);
    });

    testWidgets('disabled items are not tappable', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(_app(
        TideContextMenu(
          items: [
            TideContextMenuItem(
              label: 'Disabled',
              onTap: () => tapped = true,
              enabled: false,
            ),
          ],
          child: const SizedBox(width: 100, height: 100),
        ),
      ));

      // Open menu.
      await tester.longPress(find.byType(TideContextMenu));
      await tester.pumpAndSettle();
      expect(find.text('Disabled'), findsOneWidget);

      // Tap the disabled item — should not trigger callback.
      await tester.tap(find.text('Disabled'));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });

    testWidgets('static show() creates overlay at position', (tester) async {
      late BuildContext savedContext;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) {
                    savedContext = context;
                    return const SizedBox.expand();
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Show menu programmatically.
      TideContextMenu.show(
        context: savedContext,
        position: const Offset(100, 100),
        items: [
          TideContextMenuItem(label: 'Static Item', onTap: () {}),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Static Item'), findsOneWidget);
    });

    testWidgets('does not show when disabled', (tester) async {
      await tester.pumpWidget(_app(
        TideContextMenu(
          enabled: false,
          items: [
            TideContextMenuItem(label: 'Hidden', onTap: () {}),
          ],
          child: const SizedBox(width: 100, height: 100),
        ),
      ));

      await tester.longPress(find.byType(TideContextMenu));
      await tester.pumpAndSettle();

      expect(find.text('Hidden'), findsNothing);
    });

    testWidgets('items with icons render correctly', (tester) async {
      await tester.pumpWidget(_app(
        TideContextMenu(
          items: [
            TideContextMenuItem(
              label: 'With Icon',
              onTap: () {},
              icon: const SizedBox(
                key: Key('test-icon'),
                width: 16,
                height: 16,
              ),
            ),
          ],
          child: const SizedBox(width: 100, height: 100),
        ),
      ));

      await tester.longPress(find.byType(TideContextMenu));
      await tester.pumpAndSettle();

      expect(find.text('With Icon'), findsOneWidget);
      expect(find.byKey(const Key('test-icon')), findsOneWidget);
    });
  });
}
