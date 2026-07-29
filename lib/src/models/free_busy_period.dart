import '../common/calendar_enums.dart';
import 'package:timezone/timezone.dart';

/// A single merged period of non-free time, produced by
/// [FreeBusyPeriod.merge] (used by `DeviceCalendarPlugin.retrieveFreeBusy`)
/// from one or more overlapping/adjacent events.
class FreeBusyPeriod {
  final TZDateTime start;
  final TZDateTime end;

  /// The most restrictive [Availability] among the events this period was
  /// merged from (`Unavailable` > `Busy` > `Tentative`). Never [Availability.Free]
  /// -- free time never produces a period.
  final Availability status;

  const FreeBusyPeriod({
    required this.start,
    required this.end,
    required this.status,
  });

  @override
  bool operator ==(Object other) =>
      other is FreeBusyPeriod &&
      start.isAtSameMomentAs(other.start) &&
      end.isAtSameMomentAs(other.end) &&
      status == other.status;

  @override
  int get hashCode => Object.hash(start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch, status);

  @override
  String toString() =>
      'FreeBusyPeriod($status, ${start.toIso8601String()} - ${end.toIso8601String()})';

  static int _priority(Availability status) {
    switch (status) {
      case Availability.Unavailable:
        return 3;
      case Availability.Busy:
        return 2;
      case Availability.Tentative:
        return 1;
      case Availability.Free:
        return 0;
    }
  }

  /// Merges overlapping and touching (`a.end == b.start`) periods into one,
  /// in time order. When periods with different [status]es overlap, the
  /// merged period keeps whichever is more restrictive
  /// (`Unavailable` > `Busy` > `Tentative`) rather than splitting into
  /// sub-segments per status change.
  static List<FreeBusyPeriod> merge(List<FreeBusyPeriod> periods) {
    if (periods.isEmpty) return [];

    final sorted = [...periods]..sort((a, b) => a.start.compareTo(b.start));
    final merged = <FreeBusyPeriod>[sorted.first];

    for (final period in sorted.skip(1)) {
      final last = merged.last;
      if (!period.start.isAfter(last.end)) {
        final mergedEnd = period.end.isAfter(last.end) ? period.end : last.end;
        final mergedStatus = _priority(period.status) > _priority(last.status)
            ? period.status
            : last.status;
        merged[merged.length - 1] = FreeBusyPeriod(
          start: last.start,
          end: mergedEnd,
          status: mergedStatus,
        );
      } else {
        merged.add(period);
      }
    }

    return merged;
  }
}
