import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarColor', () {
    // No fromJson/toJson exists on this class either -- see the note in
    // event_color_test.dart. Plain positional-field value holder.
    test('Constructor_SetsColorAndColorKey', () {
      final color = CalendarColor(0xff00ff00, 2);
      expect(color.color, 0xff00ff00);
      expect(color.colorKey, 2);
    });

    test('ToString_IncludesColorAndColorKey', () {
      final color = CalendarColor(0xff00ff00, 2);
      expect(color.toString(), contains('${0xff00ff00}'));
      expect(color.toString(), contains('2'));
    });
  });
}
