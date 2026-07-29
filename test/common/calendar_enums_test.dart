import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DayOfWeekExtension', () {
    test('DayOfWeekExtension_Value_AllDays', () {
      expect(DayOfWeek.Monday.value, 1);
      expect(DayOfWeek.Tuesday.value, 2);
      expect(DayOfWeek.Wednesday.value, 3);
      expect(DayOfWeek.Thursday.value, 4);
      expect(DayOfWeek.Friday.value, 5);
      expect(DayOfWeek.Saturday.value, 6);
      // The one non-obvious mapping: ISO weekdays start at Monday=1, but
      // this enum maps Sunday to 0, not 7.
      expect(DayOfWeek.Sunday.value, 0);
    });

    test('DayOfWeekExtension_EnumToString_AllDays', () {
      for (final day in DayOfWeek.values) {
        expect(day.enumToString, day.toString().split('.').last);
      }
    });
  });

  group('DaysOfWeekGroupExtension.getDays', () {
    test('GetDays_Weekday_ReturnsFiveWeekdays', () {
      expect(
        DayOfWeekGroup.Weekday.getDays,
        [
          DayOfWeek.Monday,
          DayOfWeek.Tuesday,
          DayOfWeek.Wednesday,
          DayOfWeek.Thursday,
          DayOfWeek.Friday,
        ],
      );
    });

    test('GetDays_Weekend_ReturnsTwoDays', () {
      expect(DayOfWeekGroup.Weekend.getDays,
          [DayOfWeek.Saturday, DayOfWeek.Sunday]);
    });

    test('GetDays_AllDays_ReturnsAllSevenDays', () {
      expect(DayOfWeekGroup.AllDays.getDays, DayOfWeek.values);
    });

    test('GetDays_None_ReturnsEmpty', () {
      expect(DayOfWeekGroup.None.getDays, isEmpty);
    });
  });

  group('MonthOfYearExtension', () {
    test('MonthOfYearExtension_Value_AllMonths', () {
      const expected = {
        MonthOfYear.January: 1,
        MonthOfYear.Feburary: 2,
        MonthOfYear.March: 3,
        MonthOfYear.April: 4,
        MonthOfYear.May: 5,
        MonthOfYear.June: 6,
        MonthOfYear.July: 7,
        MonthOfYear.August: 8,
        MonthOfYear.September: 9,
        MonthOfYear.October: 10,
        MonthOfYear.November: 11,
        MonthOfYear.December: 12,
      };
      expected.forEach((month, value) {
        expect(month.value, value);
      });
    });

    test('MonthOfYearExtension_EnumToString_AllMonths', () {
      // Testing the enum as written -- `Feburary` is misspelled in the enum
      // itself. Not fixed here as a side effect of writing this test.
      for (final month in MonthOfYear.values) {
        expect(month.enumToString, month.toString().split('.').last);
      }
      expect(MonthOfYear.Feburary.enumToString, 'Feburary');
    });
  });

  group('WeekNumberExtension', () {
    test('WeekNumberExtension_Value_FirstThroughFourth', () {
      expect(WeekNumber.First.value, 1);
      expect(WeekNumber.Second.value, 2);
      expect(WeekNumber.Third.value, 3);
      expect(WeekNumber.Fourth.value, 4);
    });

    test('WeekNumberExtension_Value_Last_IsNegativeOne', () {
      expect(WeekNumber.Last.value, -1);
    });
  });

  group('IntExtensions.getDayOfWeekEnumValue', () {
    test('GetDayOfWeekEnumValue_RoundTripsEveryValidInt', () {
      for (final day in DayOfWeek.values) {
        expect(day.value.getDayOfWeekEnumValue, day);
      }
    });

    test('GetDayOfWeekEnumValue_OutOfRangeInt_DefaultsToMonday', () {
      expect(99.getDayOfWeekEnumValue, DayOfWeek.Monday);
    });
  });

  group('IntExtensions.getMonthOfYearEnumValue', () {
    test('GetMonthOfYearEnumValue_RoundTripsEveryValidInt', () {
      for (final month in MonthOfYear.values) {
        expect(month.value.getMonthOfYearEnumValue, month);
      }
    });

    test('GetMonthOfYearEnumValue_OutOfRangeInt_DefaultsToJanuary', () {
      expect(99.getMonthOfYearEnumValue, MonthOfYear.January);
    });
  });

  group('IntExtensions.getWeekNumberEnumValue', () {
    test('GetWeekNumberEnumValue_RoundTripsEveryValidInt', () {
      for (final week in WeekNumber.values) {
        expect(week.value.getWeekNumberEnumValue, week);
      }
    });

    test('GetWeekNumberEnumValue_OutOfRangeInt_DefaultsToFirst', () {
      expect(99.getWeekNumberEnumValue, WeekNumber.First);
    });
  });

  group('AvailabilityExtensions.enumToString', () {
    test('EnumToString_AllValues', () {
      expect(Availability.Busy.enumToString, 'BUSY');
      expect(Availability.Free.enumToString, 'FREE');
      expect(Availability.Tentative.enumToString, 'TENTATIVE');
      expect(Availability.Unavailable.enumToString, 'UNAVAILABLE');
    });
  });

  group('EventStatusExtensions.enumToString', () {
    test('EnumToString_AllValues', () {
      expect(EventStatus.Confirmed.enumToString, 'CONFIRMED');
      expect(EventStatus.Tentative.enumToString, 'TENTATIVE');
      expect(EventStatus.Canceled.enumToString, 'CANCELED');
      expect(EventStatus.None.enumToString, 'NONE');
    });
  });

  group('CalendarAccessLevelExtensions.enumToString', () {
    test('EnumToString_Full', () {
      expect(CalendarAccessLevel.full.enumToString, 'FULL');
    });

    test('EnumToString_WriteOnly', () {
      expect(CalendarAccessLevel.writeOnly.enumToString, 'WRITE_ONLY');
    });
  });
}
