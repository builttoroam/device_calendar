import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Calendar', () {
    test('FromJson_ToJson_RoundTrip_AllFieldsPopulated', () {
      final calendar = Calendar(
        id: '1',
        name: 'Home',
        isReadOnly: true,
        isDefault: false,
        color: 0xff00ff00,
        accountName: 'account@example.com',
        accountType: 'com.google',
      );
      final roundTripped = Calendar.fromJson(calendar.toJson());
      expect(roundTripped.id, calendar.id);
      expect(roundTripped.name, calendar.name);
      expect(roundTripped.isReadOnly, calendar.isReadOnly);
      expect(roundTripped.isDefault, calendar.isDefault);
      expect(roundTripped.color, calendar.color);
      expect(roundTripped.accountName, calendar.accountName);
      expect(roundTripped.accountType, calendar.accountType);
    });

    test('FromJson_ToJson_RoundTrip_OptionalFieldsAbsent', () {
      final roundTripped = Calendar.fromJson(Calendar().toJson());
      expect(roundTripped.id, isNull);
      expect(roundTripped.name, isNull);
      expect(roundTripped.isReadOnly, isNull);
      expect(roundTripped.isDefault, isNull);
      expect(roundTripped.color, isNull);
      expect(roundTripped.accountName, isNull);
      expect(roundTripped.accountType, isNull);
    });

    test('FromJson_IsReadOnly_LiteralBoolean_ParsesCorrectly', () {
      final calendar = Calendar.fromJson({'isReadOnly': true});
      expect(calendar.isReadOnly, isTrue);
    });

    test('FromJson_IsReadOnly_StringValue_ThrowsTypeError', () {
      // Calendar.fromJson assigns json['isReadOnly'] straight into a `bool?`
      // field with no parsing step. If the native side ever sent a string
      // "true"/"false" instead of a JSON boolean, this throws a TypeError at
      // runtime rather than silently coercing it -- pinning down the actual
      // (unforgiving) contract here, since the plan's original assumption
      // ("check what the native side sends") turned out moot: whatever it
      // sends, only a real bool works.
      expect(() => Calendar.fromJson({'isReadOnly': 'true'}),
          throwsA(isA<TypeError>()));
    });
  });
}
