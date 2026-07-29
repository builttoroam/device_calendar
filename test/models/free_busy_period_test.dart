import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

TZDateTime _t(int hour) => TZDateTime.utc(2024, 1, 1, hour);

void main() {
  group('FreeBusyPeriod.merge', () {
    test('EmptyList_ReturnsEmpty', () {
      expect(FreeBusyPeriod.merge([]), isEmpty);
    });

    test('SinglePeriod_ReturnedUnchanged', () {
      final period = FreeBusyPeriod(
          start: _t(9), end: _t(10), status: Availability.Busy);
      expect(FreeBusyPeriod.merge([period]), [period]);
    });

    test('DisjointPeriods_StayseparateInTimeOrder', () {
      final earlyPeriod =
          FreeBusyPeriod(start: _t(9), end: _t(10), status: Availability.Busy);
      final latePeriod = FreeBusyPeriod(
          start: _t(14), end: _t(15), status: Availability.Busy);

      // Passed in reverse order to also assert sorting.
      final merged = FreeBusyPeriod.merge([latePeriod, earlyPeriod]);
      expect(merged, [earlyPeriod, latePeriod]);
    });

    test('AdjacentPeriods_TouchingEndToStart_Merge', () {
      final first =
          FreeBusyPeriod(start: _t(9), end: _t(10), status: Availability.Busy);
      final second = FreeBusyPeriod(
          start: _t(10), end: _t(11), status: Availability.Busy);

      final merged = FreeBusyPeriod.merge([first, second]);
      expect(merged, [
        FreeBusyPeriod(start: _t(9), end: _t(11), status: Availability.Busy),
      ]);
    });

    test('OverlappingPeriods_Merge', () {
      final first =
          FreeBusyPeriod(start: _t(9), end: _t(11), status: Availability.Busy);
      final second = FreeBusyPeriod(
          start: _t(10), end: _t(12), status: Availability.Busy);

      final merged = FreeBusyPeriod.merge([first, second]);
      expect(merged, [
        FreeBusyPeriod(start: _t(9), end: _t(12), status: Availability.Busy),
      ]);
    });

    test('OverlappingPeriods_KeepsMoreRestrictiveStatus', () {
      final tentative = FreeBusyPeriod(
          start: _t(9), end: _t(11), status: Availability.Tentative);
      final unavailable = FreeBusyPeriod(
          start: _t(10), end: _t(12), status: Availability.Unavailable);

      final merged = FreeBusyPeriod.merge([tentative, unavailable]);
      expect(merged.single.status, Availability.Unavailable);
      expect(merged.single.start, _t(9));
      expect(merged.single.end, _t(12));
    });

    test('OverlappingPeriods_BusyBeatsTentativeRegardlessOfOrder', () {
      final busy =
          FreeBusyPeriod(start: _t(9), end: _t(11), status: Availability.Busy);
      final tentative = FreeBusyPeriod(
          start: _t(10), end: _t(12), status: Availability.Tentative);

      expect(FreeBusyPeriod.merge([busy, tentative]).single.status,
          Availability.Busy);
      expect(FreeBusyPeriod.merge([tentative, busy]).single.status,
          Availability.Busy);
    });

    test('FullyContainedPeriod_MergesWithoutExtendingEnd', () {
      final outer =
          FreeBusyPeriod(start: _t(9), end: _t(17), status: Availability.Busy);
      final inner = FreeBusyPeriod(
          start: _t(10), end: _t(11), status: Availability.Tentative);

      final merged = FreeBusyPeriod.merge([outer, inner]);
      expect(merged, [
        FreeBusyPeriod(start: _t(9), end: _t(17), status: Availability.Busy),
      ]);
    });

    test('AllDayPeriod_TreatedAsAnOrdinaryLongPeriod', () {
      final allDay = FreeBusyPeriod(
          start: TZDateTime.utc(2024, 1, 1),
          end: TZDateTime.utc(2024, 1, 2),
          status: Availability.Busy);
      final withinDay = FreeBusyPeriod(
          start: _t(9), end: _t(10), status: Availability.Tentative);

      final merged = FreeBusyPeriod.merge([allDay, withinDay]);
      expect(merged, [
        FreeBusyPeriod(
            start: TZDateTime.utc(2024, 1, 1),
            end: TZDateTime.utc(2024, 1, 2),
            status: Availability.Busy),
      ]);
    });

    test('ThreePeriodChain_MergesIntoOne', () {
      final a =
          FreeBusyPeriod(start: _t(9), end: _t(10), status: Availability.Busy);
      final b = FreeBusyPeriod(
          start: _t(10), end: _t(11), status: Availability.Tentative);
      final c = FreeBusyPeriod(
          start: _t(11), end: _t(12), status: Availability.Unavailable);

      final merged = FreeBusyPeriod.merge([a, b, c]);
      expect(merged, [
        FreeBusyPeriod(
            start: _t(9), end: _t(12), status: Availability.Unavailable),
      ]);
    });
  });

  group('FreeBusyPeriod equality', () {
    test('SameStartEndStatus_AreEqual', () {
      final a =
          FreeBusyPeriod(start: _t(9), end: _t(10), status: Availability.Busy);
      final b =
          FreeBusyPeriod(start: _t(9), end: _t(10), status: Availability.Busy);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('DifferentStatus_AreNotEqual', () {
      final a =
          FreeBusyPeriod(start: _t(9), end: _t(10), status: Availability.Busy);
      final b = FreeBusyPeriod(
          start: _t(9), end: _t(10), status: Availability.Tentative);
      expect(a, isNot(equals(b)));
    });
  });
}
