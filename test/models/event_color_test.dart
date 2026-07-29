import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventColor', () {
    // No fromJson/toJson exists on this class (the plan's assumption that
    // one does was wrong) -- Event.toJson/fromJson only reads/writes the
    // plain int color/colorKey fields via Event.updateEventColor, tested in
    // event_test.dart. This class is just a positional-field value holder.
    test('Constructor_SetsColorAndColorKey', () {
      final color = EventColor(0xffff0000, 5);
      expect(color.color, 0xffff0000);
      expect(color.colorKey, 5);
    });

    test('ToString_IncludesColorAndColorKey', () {
      final color = EventColor(0xffff0000, 5);
      expect(color.toString(), contains('${0xffff0000}'));
      expect(color.toString(), contains('5'));
    });
  });
}
