// Cross-language contract check (TESTING_PLAN.md section 4).
//
// The method channel between Dart, Kotlin and Swift is a stringly-typed
// `Map<String, Object?>` -- there's no compiler to catch a key spelled
// differently on one side. This script extracts every argument-key string
// literal used to build/read those maps in each of the three languages and
// checks for drift between them.
//
// Run with: dart run tool/check_channel_argument_contract.dart
//
// Note on scope: `Calendar` objects flow back from Kotlin as Gson-serialized
// plain fields (android/.../models/Calendar.kt), not via the ARGUMENT-style
// constants this script checks -- calendar.dart is intentionally excluded.
import 'dart:io';

final repoRoot = Directory.current.path;

void main() {
  final kotlin = _extractArguments(
    '$repoRoot/android/src/main/kotlin/com/builttoroam/devicecalendar/DeviceCalendarPlugin.kt',
    RegExp('''private const val \\w+_ARGUMENT\\s*=\\s*"([^"]*)"'''),
  );
  final swift = _extractArguments(
    '$repoRoot/ios/Classes/SwiftDeviceCalendarPlugin.swift',
    RegExp('''let \\w+Argument\\s*=\\s*"([^"]*)"'''),
  );
  final dart = _extractDartArguments();

  // Request-direction args (Dart -> native) go through the explicit
  // ARGUMENT-constant constants above. Response-direction fields (native ->
  // Dart, e.g. Event/Attendee/Reminder objects coming back from
  // retrieveEvents) instead go through Gson (Kotlin) / Codable (Swift)
  // reflection over these model classes' field names -- a second,
  // structurally different serialization mechanism that also needs to
  // agree with Dart's JSON keys.
  final kotlinModelFields = _extractKotlinModelFields([
    '$repoRoot/android/src/main/kotlin/com/builttoroam/devicecalendar/models/Event.kt',
    '$repoRoot/android/src/main/kotlin/com/builttoroam/devicecalendar/models/Attendee.kt',
    '$repoRoot/android/src/main/kotlin/com/builttoroam/devicecalendar/models/Reminder.kt',
  ]);
  final swiftModelFields =
      _extractSwiftStructFields('$repoRoot/ios/Classes/SwiftDeviceCalendarPlugin.swift');

  final kotlinValues = kotlin.union(kotlinModelFields);
  final swiftValues = swift.union(swiftModelFields);

  final dartNotInKotlin = dart.difference(kotlinValues);
  final kotlinNotInDart = kotlinValues.difference(dart);
  final swiftNotInDart = swiftValues.difference(dart);
  final swiftNotInKotlin = swiftValues.difference(kotlinValues);

  print('Kotlin argument keys: ${kotlinValues.length}');
  print('Swift argument keys:  ${swiftValues.length}');
  print('Dart argument keys:   ${dart.length}');
  print('');

  // Informational: keys that exist on only one or two platforms are often
  // legitimate platform-exclusive features (e.g. originalInstanceTime,
  // eventColorKey and calendarColorKey are Android-only; see event.dart's
  // own "Android exclusive" doc comments). Printed for visibility, not
  // failed on.
  if (kotlinNotInDart.isNotEmpty) {
    print('In Kotlin but not sent by Dart (dead code on the Kotlin side, '
        'or Dart genuinely never needs to send it): $kotlinNotInDart');
  }
  if (swiftNotInDart.isNotEmpty) {
    print('In Swift but not sent by Dart: $swiftNotInDart');
  }
  if (swiftNotInKotlin.isNotEmpty) {
    print('In Swift but not in Kotlin (iOS-only keys, e.g. RRULE string '
        'encoding helpers like day/occurrence): $swiftNotInKotlin');
  }

  // The one assertion that's actually low-noise and catches real drift:
  // everything Dart sends over the channel must be a key at least one
  // native side actually reads. A Dart key that's in neither Kotlin nor
  // Swift's constant set can only be a typo or dead code -- there's no
  // legitimate "Dart-only" argument key, since Dart only builds these maps
  // to send them across the channel.
  final dartOrphans = dartNotInKotlin.difference(swiftValues);

  if (dartOrphans.isNotEmpty) {
    stderr.writeln('');
    stderr.writeln('FAIL: Dart sends argument key(s) that neither Kotlin '
        'nor Swift ever reads: $dartOrphans');
    stderr.writeln('This is either a typo (drifted from the native side\'s '
        'spelling) or dead code -- check DeviceCalendarPlugin.kt and '
        'SwiftDeviceCalendarPlugin.swift.');
    exit(1);
  }

  print('');
  print('OK: every argument key Dart sends is read by at least one native '
      'platform.');
}

Set<String> _extractArguments(String path, RegExp pattern) {
  final content = File(path).readAsStringSync();
  return {
    for (final m in pattern.allMatches(content)) m.group(1)!,
  };
}

Set<String> _extractKotlinModelFields(List<String> paths) {
  final pattern = RegExp('''^\\s*(?:var|val) (\\w+)\\s*:''', multiLine: true);
  return {
    for (final path in paths)
      for (final m in pattern.allMatches(File(path).readAsStringSync()))
        m.group(1)!,
  };
}

Set<String> _extractSwiftStructFields(String path) {
  // Struct/response-model field declarations use `let name: Type`; local
  // variables extracted from `arguments` use `let name = expr` (no colon
  // right after the name), so this pattern stays selective without needing
  // to track struct boundaries.
  final pattern = RegExp('''^\\s*let (\\w+)\\s*:''', multiLine: true);
  return {
    for (final m in pattern.allMatches(File(path).readAsStringSync()))
      m.group(1)!,
  };
}

Set<String> _extractDartArguments() {
  final values = <String>{};

  // ChannelConstants' method-level argument names (calendarId, startDate,
  // followingInstances, etc.) -- excludes methodName* (channel method
  // names, not argument keys).
  final channelConstantsContent = File(
    '$repoRoot/lib/src/common/channel_constants.dart',
  ).readAsStringSync();
  final fieldPattern =
      RegExp('''static const String (\\w+) = '([^']*)';''');
  for (final m in fieldPattern.allMatches(channelConstantsContent)) {
    final name = m.group(1)!;
    if (name.startsWith('parameter')) {
      values.add(m.group(2)!);
    }
  }

  // Event/Attendee/Reminder/AttendeeDetails model classes: every JSON key
  // string literal used to build or read the maps sent over the channel
  // (data['x'] = ..., 'x': ..., json['x']). This also picks up the nested
  // recurrenceRule keys (byday, bymonthday, ...) via the cast-fixup lines
  // in event.dart.
  final modelFiles = [
    'lib/src/models/event.dart',
    'lib/src/models/attendee.dart',
    'lib/src/models/reminder.dart',
    'lib/src/models/platform_specifics/android/attendee_details.dart',
    'lib/src/models/platform_specifics/ios/attendee_details.dart',
  ];
  final bracketKeyPattern = RegExp('''\\[['"](\\w+)['"]\\]''');
  for (final relativePath in modelFiles) {
    final content = File('$repoRoot/$relativePath').readAsStringSync();
    for (final m in bracketKeyPattern.allMatches(content)) {
      values.add(m.group(1)!);
    }
  }

  return values;
}
