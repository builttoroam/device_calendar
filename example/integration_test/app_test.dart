import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';

import 'package:device_calendar_example/main.dart' as app;

Finder keyFinder(String key) {
  return find.byKey(Key(key));
}

Finder textFinder(String key) {
  return find.text(key);
}

/// NOTE: These integration tests are currently made to be run on a physical device where there is at least a calendar that can be written to.
/// Calendar permissions are needed. See example/test_driver/integration_test.dart for how to run this on Android
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('Calendar plugin example', () {
    final eventTitle = const Uuid().v1();
    final saveEventButtonFinder = find.byKey(const Key('saveEventButton'));
    final sampleEvent = {
      'titleField': eventTitle,
      'descriptionField': 'Remember to buy flowers...',
      'locationField': 'Sydney',
      'urlField': 'https://google.com'
    };
//TODO: remove redundant restarts. Currently needed because the first screen is always "test starting..."
    testWidgets('starts on calendars page', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('calendarsPage')), findsOneWidget);
    });
    testWidgets('select first writable calendar', (WidgetTester tester) async {
      app.main();

      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(keyFinder('writableCalendar0'), findsOneWidget);
    });
    testWidgets('go to add event page', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(keyFinder('writableCalendar0'));

      await tester.pumpAndSettle();
      expect(keyFinder('addEventButton'), findsOneWidget);
      print('found add event button');
      await tester.tap(keyFinder('addEventButton'));
      await tester.pumpAndSettle();
      expect(keyFinder('saveEventButton'), findsOneWidget);
    });
    testWidgets('try to save event without entering mandatory fields',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(keyFinder('writableCalendar0'));
      await tester.pumpAndSettle();
      await tester.tap(keyFinder('addEventButton'));

      await tester.pumpAndSettle();
      await tester.tap(keyFinder('saveEventButton'));
      await tester.pumpAndSettle();
      expect(find.text('Please fix the errors in red before submitting.'),
          findsOneWidget);
    });
    testWidgets('save event with title $eventTitle',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(keyFinder('writableCalendar0'));
      await tester.pumpAndSettle();
      await tester.tap(keyFinder('addEventButton'));

      await tester.pumpAndSettle();
      for (var i = 0; i < sampleEvent.length; i++) {
        await tester.tap(keyFinder(sampleEvent.keys.elementAt(i)));
        await tester.enterText(keyFinder(sampleEvent.keys.elementAt(i)),
            sampleEvent.values.elementAt(i));
      }
      await tester.tap(keyFinder('saveEventButton'));
      await tester.pumpAndSettle();
      expect(textFinder(eventTitle), findsOneWidget);
    });
    });
    testWidgets('delete event with title $eventTitle',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(keyFinder('writableCalendar0'));
      await tester.pumpAndSettle();
      await tester.tap(textFinder(eventTitle));

      await tester.scrollUntilVisible(keyFinder('deleteEventButton'), -5);
      await tester.tap(keyFinder('deleteEventButton'));
      await tester.pumpAndSettle();
      expect(textFinder(eventTitle), findsNothing);
    });
  });
}
