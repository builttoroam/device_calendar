enum DayOfWeek {
  Monday,
  Tuesday,
  Wednesday,
  Thursday,
  Friday,
  Saturday,
  Sunday,
}

enum DayOfWeekGroup {
  None,
  Weekday,
  Weekend,
  AllDays,
}

enum MonthOfYear {
  January,
  Feburary,
  March,
  April,
  May,
  June,
  July,
  August,
  September,
  October,
  November,
  December,
}

enum WeekNumber {
  First,
  Second,
  Third,
  Fourth,
  Last,
}

enum AttendeeRole {
  None,
  Required,
  Optional,
  Resource,
}

enum Availability {
  Free,
  Busy,
  Tentative,
  Unavailable,
}

extension DayOfWeekExtension on DayOfWeek {
  static int _value(DayOfWeek val) {
    switch (val) {
      case DayOfWeek.Monday:
        return 1;
      case DayOfWeek.Tuesday:
        return 2;
      case DayOfWeek.Wednesday:
        return 3;
      case DayOfWeek.Thursday:
        return 4;
      case DayOfWeek.Friday:
        return 5;
      case DayOfWeek.Saturday:
        return 6;
      case DayOfWeek.Sunday:
        return 0;
      default:
        return 1;
    }
  }

  String _enumToString(DayOfWeek enumValue) {
    return enumValue.toString().split('.').last;
  }

  int get value => _value(this);
  String get enumToString => _enumToString(this);
}

extension DaysOfWeekGroupExtension on DayOfWeekGroup {
  static List<DayOfWeek> _getDays(DayOfWeekGroup val) {
    switch (val) {
      case DayOfWeekGroup.Weekday:
        return [
          DayOfWeek.Monday,
          DayOfWeek.Tuesday,
          DayOfWeek.Wednesday,
          DayOfWeek.Thursday,
          DayOfWeek.Friday
        ];
      case DayOfWeekGroup.Weekend:
        return [DayOfWeek.Saturday, DayOfWeek.Sunday];
      case DayOfWeekGroup.AllDays:
        return [
          DayOfWeek.Monday,
          DayOfWeek.Tuesday,
          DayOfWeek.Wednesday,
          DayOfWeek.Thursday,
          DayOfWeek.Friday,
          DayOfWeek.Saturday,
          DayOfWeek.Sunday
        ];
      default:
        return [];
    }
  }

  String _enumToString(DayOfWeekGroup enumValue) {
    return enumValue.toString().split('.').last;
  }

  List<DayOfWeek> get getDays => _getDays(this);
  String get enumToString => _enumToString(this);
}

extension MonthOfYearExtension on MonthOfYear {
  static int _value(MonthOfYear val) {
    switch (val) {
      case MonthOfYear.January:
        return 1;
      case MonthOfYear.Feburary:
        return 2;
      case MonthOfYear.March:
        return 3;
      case MonthOfYear.April:
        return 4;
      case MonthOfYear.May:
        return 5;
      case MonthOfYear.June:
        return 6;
      case MonthOfYear.July:
        return 7;
      case MonthOfYear.August:
        return 8;
      case MonthOfYear.September:
        return 9;
      case MonthOfYear.October:
        return 10;
      case MonthOfYear.November:
        return 11;
      case MonthOfYear.December:
        return 12;
      default:
        return 1;
    }
  }

  String _enumToString(MonthOfYear enumValue) {
    return enumValue.toString().split('.').last;
  }

  int get value => _value(this);
  String get enumToString => _enumToString(this);
}

extension WeekNumberExtension on WeekNumber {
  static int _value(WeekNumber val) {
    switch (val) {
      case WeekNumber.First:
        return 1;
      case WeekNumber.Second:
        return 2;
      case WeekNumber.Third:
        return 3;
      case WeekNumber.Fourth:
        return 4;
      case WeekNumber.Last:
        return -1;
      default:
        return 1;
    }
  }

  String _enumToString(WeekNumber enumValue) {
    return enumValue.toString().split('.').last;
  }

  int get value => _value(this);
  String get enumToString => _enumToString(this);
}

extension IntExtensions on int {
  static DayOfWeek _getDayOfWeekEnumValue(int val) {
    switch (val) {
      case 1:
        return DayOfWeek.Monday;
      case 2:
        return DayOfWeek.Tuesday;
      case 3:
        return DayOfWeek.Wednesday;
      case 4:
        return DayOfWeek.Thursday;
      case 5:
        return DayOfWeek.Friday;
      case 6:
        return DayOfWeek.Saturday;
      case 0:
        return DayOfWeek.Sunday;
      default:
        return DayOfWeek.Monday;
    }
  }

  static MonthOfYear _getMonthOfYearEnumValue(int val) {
    switch (val) {
      case 1:
        return MonthOfYear.January;
      case 2:
        return MonthOfYear.Feburary;
      case 3:
        return MonthOfYear.March;
      case 4:
        return MonthOfYear.April;
      case 5:
        return MonthOfYear.May;
      case 6:
        return MonthOfYear.June;
      case 7:
        return MonthOfYear.July;
      case 8:
        return MonthOfYear.August;
      case 9:
        return MonthOfYear.September;
      case 10:
        return MonthOfYear.October;
      case 11:
        return MonthOfYear.November;
      case 12:
        return MonthOfYear.December;
      default:
        return MonthOfYear.January;
    }
  }

  static WeekNumber _getWeekNumberEnumValue(int val) {
    switch (val) {
      case 1:
        return WeekNumber.First;
      case 2:
        return WeekNumber.Second;
      case 3:
        return WeekNumber.Third;
      case 4:
        return WeekNumber.Fourth;
      case -1:
        return WeekNumber.Last;
      default:
        return WeekNumber.First;
    }
  }

  DayOfWeek get getDayOfWeekEnumValue => _getDayOfWeekEnumValue(this);
  MonthOfYear get getMonthOfYearEnumValue => _getMonthOfYearEnumValue(this);
  WeekNumber get getWeekNumberEnumValue => _getWeekNumberEnumValue(this);
}

extension RoleExtensions on AttendeeRole {
  String _enumToString(AttendeeRole enumValue) {
    return enumValue.toString().split('.').last;
  }

  String get enumToString => _enumToString(this);
}

extension AvailabilityExtensions on Availability {
  String _enumToString(Availability enumValue) {
    switch (enumValue) {
      case Availability.Busy:
        return 'BUSY';
        break;
      case Availability.Free:
        return 'FREE';
        break;
      case Availability.Tentative:
        return 'TENTATIVE';
        break;
      case Availability.Unavailable:
        return 'UNAVAILABLE';
        break;
    }
    return null;
  }

  String get enumToString => _enumToString(this);
}
