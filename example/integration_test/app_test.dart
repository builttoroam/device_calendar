import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';

import 'package:device_calendar_example/main.dart' as app;

/// NOTE: These integration tests are currently made to be run on a physical device where there is at least a calendar that can be written to.
/// Calendar permissions are needed. See example/test_driver/integration_test.dart for how to run this on Android
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('Calendar plugin example', () {
    final eventTitle = Uuid().v1();
    final saveEventButtonFinder = find.byKey(const Key('saveEventButton'));
    final eventTitleFinder = find.text(eventTitle);
    final firstWritableCalendarFinder =
        find.byKey(const Key('writableCalendar0'));
    final addEventButtonFinder = find.byKey(const Key('addEventButton'));
    final titleFieldFinder = find.byKey(const Key('titleField'));
    final deleteButtonFinder = find.byKey(const Key('deleteEventButton'));
//TODO: remove redundant restarts. Currently needed because the first screen is always "test starting..."
    testWidgets('starts on calendars page', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('calendarsPage')), findsOneWidget);
    });
    testWidgets('select first writable calendar', (WidgetTester tester) async {
      app.main();

      await tester.pumpAndSettle(Duration(milliseconds: 500));
      expect(firstWritableCalendarFinder, findsOneWidget);
    });
    testWidgets('go to add event page', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(firstWritableCalendarFinder);

      await tester.pumpAndSettle();
      expect(addEventButtonFinder, findsOneWidget);
      debugPrint('found add event button');
      await tester.tap(addEventButtonFinder);
      await tester.pumpAndSettle();
      expect(saveEventButtonFinder, findsOneWidget);
    });
    testWidgets('try to save event without entering mandatory fields',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(firstWritableCalendarFinder);
      await tester.pumpAndSettle();
      await tester.tap(addEventButtonFinder);

      await tester.pumpAndSettle();
      await tester.tap(saveEventButtonFinder);
      await tester.pumpAndSettle();
      expect(find.text('Please fix the errors in red before submitting.'),
          findsOneWidget);
    });
    testWidgets('save event with title $eventTitle',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(firstWritableCalendarFinder);
      await tester.pumpAndSettle();
      await tester.tap(addEventButtonFinder);

      await tester.pumpAndSettle();
      await tester.tap(titleFieldFinder);

      await tester.enterText(titleFieldFinder, eventTitle);
      await tester.tap(saveEventButtonFinder);
      await tester.pumpAndSettle();
      expect(eventTitleFinder, findsOneWidget);
    });
    testWidgets('delete event with title $eventTitle',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(firstWritableCalendarFinder);
      await tester.pumpAndSettle();
      await tester.tap(eventTitleFinder);

      await tester.scrollUntilVisible(deleteButtonFinder, -5);
      await tester.tap(deleteButtonFinder);
      await tester.pumpAndSettle();
      expect(eventTitleFinder, findsNothing);
    });
  });
}
