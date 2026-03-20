import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/l10n/tide_localizations.dart';

void main() {
  group('TideLocalizations.en()', () {
    final en = TideLocalizations.en();

    test('today', () => expect(en.today, 'Today'));
    test('monthView', () => expect(en.monthView, 'Month'));
    test('weekView', () => expect(en.weekView, 'Week'));
    test('dayView', () => expect(en.dayView, 'Day'));
    test('scheduleView', () => expect(en.scheduleView, 'Schedule'));
    test('noEvents', () => expect(en.noEvents, 'No events'));
    test('allDay', () => expect(en.allDay, 'All day'));
    test('moreEvents', () => expect(en.moreEvents, '+{count} more'));
    test('newEvent', () => expect(en.newEvent, 'New event'));
    test('deleteEvent', () => expect(en.deleteEvent, 'Delete'));
    test('editEvent', () => expect(en.editEvent, 'Edit'));
    test('editSeries', () => expect(en.editSeries, 'Edit series'));
    test('editOccurrence', () => expect(en.editOccurrence, 'This event only'));
    test('editThisAndFollowing',
        () => expect(en.editThisAndFollowing, 'This and following'));
    test('timelineDay', () => expect(en.timelineDay, 'Timeline day'));
    test('timelineWeek', () => expect(en.timelineWeek, 'Timeline week'));
    test('timelineMonth', () => expect(en.timelineMonth, 'Timeline month'));
    test('multiWeek', () => expect(en.multiWeek, 'Multi-week'));
    test('year', () => expect(en.year, 'Year'));
    test('workWeek', () => expect(en.workWeek, 'Work week'));
  });

  group('TideLocalizations.de()', () {
    final de = TideLocalizations.de();

    test('today', () => expect(de.today, 'Heute'));
    test('monthView', () => expect(de.monthView, 'Monat'));
    test('weekView', () => expect(de.weekView, 'Woche'));
    test('dayView', () => expect(de.dayView, 'Tag'));
    test('scheduleView', () => expect(de.scheduleView, 'Agenda'));
    test('noEvents', () => expect(de.noEvents, 'Keine Termine'));
    test('allDay', () => expect(de.allDay, 'Ganztägig'));
    test('moreEvents', () => expect(de.moreEvents, '+{count} weitere'));
    test('newEvent', () => expect(de.newEvent, 'Neuer Termin'));
    test('deleteEvent', () => expect(de.deleteEvent, 'Löschen'));
    test('editEvent', () => expect(de.editEvent, 'Bearbeiten'));
    test('editSeries', () => expect(de.editSeries, 'Serie bearbeiten'));
    test('editOccurrence',
        () => expect(de.editOccurrence, 'Nur diesen Termin'));
    test('editThisAndFollowing',
        () => expect(de.editThisAndFollowing, 'Diesen und folgende'));
    test('timelineDay', () => expect(de.timelineDay, 'Zeitleiste Tag'));
    test('timelineWeek', () => expect(de.timelineWeek, 'Zeitleiste Woche'));
    test('timelineMonth', () => expect(de.timelineMonth, 'Zeitleiste Monat'));
    test('multiWeek', () => expect(de.multiWeek, 'Mehrere Wochen'));
    test('year', () => expect(de.year, 'Jahr'));
    test('workWeek', () => expect(de.workWeek, 'Arbeitswoche'));
  });

  group('formatMoreEvents', () {
    test('English with count 3', () {
      final en = TideLocalizations.en();
      expect(en.formatMoreEvents(3), '+3 more');
    });

    test('German with count 5', () {
      final de = TideLocalizations.de();
      expect(de.formatMoreEvents(5), '+5 weitere');
    });

    test('count 0', () {
      final en = TideLocalizations.en();
      expect(en.formatMoreEvents(0), '+0 more');
    });
  });

  group('equality', () {
    test('two en() instances are equal', () {
      final a = TideLocalizations.en();
      final b = TideLocalizations.en();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('two de() instances are equal', () {
      final a = TideLocalizations.de();
      final b = TideLocalizations.de();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('en and de are not equal', () {
      final en = TideLocalizations.en();
      final de = TideLocalizations.de();
      expect(en, isNot(equals(de)));
    });

    test('identical instance is equal', () {
      final l10n = TideLocalizations.en();
      expect(l10n == l10n, isTrue);
    });

    test('not equal to non-TideLocalizations object', () {
      final l10n = TideLocalizations.en();
      expect(l10n == Object(), isFalse);
    });
  });

  group('custom instance', () {
    test('accepts custom strings', () {
      const custom = TideLocalizations(
        today: 'Hoy',
        monthView: 'Mes',
        weekView: 'Semana',
        dayView: 'Dia',
        scheduleView: 'Horario',
        noEvents: 'Sin eventos',
        allDay: 'Todo el dia',
        moreEvents: '+{count} mas',
        newEvent: 'Nuevo evento',
        deleteEvent: 'Eliminar',
        editEvent: 'Editar',
        editSeries: 'Editar serie',
        editOccurrence: 'Solo este evento',
        editThisAndFollowing: 'Este y siguientes',
        timelineDay: 'Linea de tiempo dia',
        timelineWeek: 'Linea de tiempo semana',
        timelineMonth: 'Linea de tiempo mes',
        multiWeek: 'Multi-semana',
        year: 'Ano',
        workWeek: 'Semana laboral',
      );
      expect(custom.today, 'Hoy');
      expect(custom.monthView, 'Mes');
      expect(custom.formatMoreEvents(2), '+2 mas');
    });
  });

  test('toString includes today value', () {
    final en = TideLocalizations.en();
    expect(en.toString(), contains('TideLocalizations'));
    expect(en.toString(), contains('Today'));
  });
}
