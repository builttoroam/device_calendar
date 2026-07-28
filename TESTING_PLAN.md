# Testing plan — systematic coverage for device_calendar

**Starting point (verified, not assumed):** this repo has exactly one test
file, `test/device_calendar_test.dart` (16 cases, Dart-layer only, method
channel mocked). Zero Android native tests (no `android/src/test`, no
`android/src/androidTest`, no test dependencies in `android/build.gradle.kts`
at all — the example app's own `androidTest`/`junit` deps in
`example/android/app/build.gradle.kts` are template boilerplate for the
example app, not the plugin). Zero iOS native tests. One Flutter
`integration_test` file for the example app
(`example/integration_test/app_test.dart`) that needs a physical device
with a writable calendar to run. That's the entire safety net for four
languages (Dart, Kotlin, Swift, plus the Obj-C registration shim, which is
6 lines and needs nothing).

**Updated since this plan was first written:** a separate pass (commits
`e876e75`..`f806ea1`) modernized the Android build (Kotlin DSL, AGP 9.2.0,
Gradle 9.6.1, Kotlin 2.3.20, minSdk 19→24), bumped the iOS deployment
target, fixed the GitHub Actions workflows, and brought `flutter analyze`
from 52 issues to 0 across both packages. Re-verified directly (not just
trusting the commit message) before revising this plan: `flutter build apk
--debug` now genuinely succeeds against the example app in this
environment, and `flutter analyze` is clean. This changes the "known
environment gaps" below — the Android Gradle breakage this plan originally
flagged is **gone**. Only the iOS/Xcode gap remains. Diffs elsewhere in the
plan below have been updated to match; see section 6 for the revised
sequencing this unlocks.

This plan is organized by layer, using the idiomatic test tool for each.
Every checklist item names the behavior it verifies — that description
**is** the test name (matches the existing
`RequestPermissions_WriteOnly_PassesAccessLevelArgument`-style naming in
`test/device_calendar_test.dart`; keep using it everywhere below).

## Tooling per layer

| Layer | Tool | Why |
|---|---|---|
| Dart models & plugin API (`lib/`) | `flutter_test` + `TestDefaultBinaryMessengerBinding` mock channel | Already the project's convention; no device needed, fastest feedback loop. |
| Android native (`android/src/main/kotlin`) | JUnit4 + **Robolectric** (`org.robolectric:robolectric`) for `ContentResolver`/`ContentValues`/`Cursor` shadows | Runs on the JVM, no emulator. Idiomatic for Android `ContentProvider`-based code — this is exactly Robolectric's core use case (it ships `ShadowContentResolver` specifically for this). |
| Android, real `CalendarContract` behavior | `androidTest` (androidx.test + JUnit4 `AndroidJUnitRunner`) on an emulator/device | Robolectric *shadows* `CalendarContract` rather than running the real provider; anything you don't fully trust the shadow for (recurrence exception rows, attendee joins) needs one instrumented test against a real (or emulator) calendar provider. |
| iOS native (`ios/Classes`) | XCTest, added as a new test target under `example/ios/RunnerTests` (the standard pattern for Flutter iOS plugin unit tests) | Idiomatic Apple-platform choice; no third-party framework needed. |
| Cross-platform end-to-end | `integration_test` (already in use) | Only way to exercise the real method channel + real `EKEventStore`/`CalendarContract` together. |
| Packaging | `dart pub publish --dry-run` | Already planned in TASKS.md section 4; catches metadata/packaging issues no unit test can. |
| Cross-language contract | a small script test (Dart or shell) diffing argument-key string literals across the 3 languages | Not idiomatic to any one platform, but this codebase's `EM.deleteEventInvalidArgumentsMessage`, `EVENT_ORIGINAL_INSTANCE_TIME_ARGUMENT` etc. only work if the string on both sides of the channel matches exactly — a naming drift here is a silent runtime bug, not a compile error, in any of the three languages. |

**Known environment gaps, not this plan's fault, but they gate what's
actually *runnable* right now:**
- No Xcode/Swift toolchain in this environment → the iOS test target can
  be written but not run here. Still true, unaffected by the Android
  modernization pass.
- ~~Android Gradle toolchain broken~~ — **fixed.** The Android build was
  modernized to Kotlin DSL (AGP 9.2.0, Gradle 9.6.1, Kotlin 2.3.20) and
  verified end-to-end; `flutter build apk --debug` succeeds here now.
  Section 2's Android setup can proceed directly — no more "verify the
  toolchain even works" hedge needed before writing tests against it.
  One new, non-blocking risk surfaced during that build worth watching:
  Flutter warns that `flutter_timezone` (an example-app dependency, not
  the plugin itself) applies its own Kotlin Gradle Plugin and that
  future Flutter versions will refuse to build apps with such plugins
  unless they migrate to "Built-in Kotlin." Doesn't block anything
  today; re-check if a future `flutter upgrade` starts failing the
  example app's build.

## 1. Dart layer (`lib/`) — runnable now, do this first

### `lib/src/models/event.dart` — `Event`
- [ ] `FromJson_NullJson_ThrowsArgumentError`
- [ ] `FromJson_LegacyTopLevelKeys_ThrowsFormatException` — one test per
      legacy key (`title`, `description`, `start`, `end`, `startTimeZone`,
      `endTimeZone`, `allDay`, `location`, `url`)
- [ ] `FromJson_StartTimeZone_UnknownName_DefaultsToLocal`
- [ ] `FromJson_EndTimeZone_Null_DefaultsToStartTimeZone`
- [ ] `FromJson_Url_EmptyString_IsNull`
- [ ] `FromJson_Url_Malformed_IsNullNotThrow` (post-`Uri.tryParse` fix —
      regression test for the #594/#604 change; write it so it would fail
      against the old `Uri.dataFromString` behavior)
- [ ] `FromJson_Attendees_OrganizerMatch_SetsIsOrganiser` and
      `FromJson_Attendees_OrganizerNoMatch_LeavesAttendeesUnchanged`
- [ ] `FromJson_RecurrenceRule_ListFieldsCastCorrectly` — one per
      cast-fixup already in the code: `byday`, `bymonthday`, `byyearday`,
      `byweekno`, `bymonth`, `bysetpos` (these `//TODO` comments exist
      *because* the rrule package throws on `List<dynamic>` — that's a
      regression waiting to happen if anyone "cleans up" the casts)
  - **known gap, needs a decision:** the allDay + `Platform.isAndroid`
    midnight-normalization block (`event.dart` had no direct testable
    seam for this — actually this logic lives in
    `device_calendar.dart`'s `createOrUpdateEvent`, see below, not here)
- [ ] `ToJson_RoundTrips_AllFields` — expand the existing
      `Event_Serializes_Correctly` test or split it: one assertion block
      per field group (identity, dates, attendees, recurrence, reminders,
      availability/status, color, `originalInstanceTime` — already added)
- [ ] `ParseStringToAvailability_UnknownString_DefaultsToBusy`
- [ ] `ParseStringToAvailability_CaseInsensitive`
- [ ] `ParseStringToEventStatus_UnknownString_ReturnsNull` (note: differs
      from Availability's default-to-Busy — worth a comment in the test
      itself explaining the asymmetry is intentional, not a bug)
- [ ] `UpdateStartLocation_ValidTimeZone_ReturnsTrueAndUpdates`
- [ ] `UpdateStartLocation_InvalidTimeZone_ReturnsFalseAndLeavesUnchanged`
- [ ] `UpdateEndLocation_ValidTimeZone_ReturnsTrueAndUpdates`
- [ ] `UpdateEndLocation_InvalidTimeZone_ReturnsFalseAndLeavesUnchanged`
- [ ] `UpdateEventColor_SetsColorAndColorKey`
- [ ] `UpdateEventColor_Null_ClearsColorAndColorKey`

### `lib/src/models/calendar.dart`, `attendee.dart`, `reminder.dart`, `event_color.dart`, `calendar_color.dart`
- [ ] One `FromJson`/`ToJson` round-trip test per model, all fields
      populated
- [ ] One round-trip test per model with every *optional* field null/absent
- [ ] `Attendee`: `AttendeeRole` int↔enum mapping for every role value,
      plus an out-of-range int (documents current behavior — throws?
      clamps? — whichever it is, pin it down with a test so it can't
      silently change)
- [ ] `Calendar`: `isReadOnly`/`isDefault` boolean parsing from both
      literal booleans and (if the native side ever sends them) string
      "true"/"false" — check what the Kotlin/Swift side actually sends
      before assuming; write the test to match reality, not assumption

### `lib/src/models/result.dart` — `Result<T>`
- [ ] `IsSuccess_NoErrorsNoData_True/False` — pin down the exact
      contract (does `isSuccess` depend on `data != null`, or only on
      `errors.isEmpty`? Read the source once, then test both branches so
      the contract is explicit instead of implicit)
- [ ] `HasErrors_ReflectsErrorsList`
- [ ] `ResultError_FieldsSetCorrectly`

### `lib/src/models/retrieve_events_params.dart`
- [ ] Construction with only `eventIds`, only dates, both, neither —
      note this class itself does no validation (validation lives in
      `DeviceCalendarPlugin.retrieveEvents`, tested below) — one test here
      just pins the "dumb data holder" contract so nobody adds silent
      validation here later without a test forcing the decision

### `lib/src/common/calendar_enums.dart` — every extension, every value
- [ ] `DayOfWeekExtension.value` — all 7 days, explicitly asserting
      `Sunday == 0` (the one non-obvious mapping — ISO vs. `Calendar`
      day-numbering mismatch, easy to regress)
- [ ] `DayOfWeekExtension.enumToString` — all 7
- [ ] `DaysOfWeekGroupExtension.getDays` — `Weekday` (5 days),
      `Weekend` (2 days), `AllDays` (7 days), `None` (empty)
- [ ] `MonthOfYearExtension.value`/`enumToString` — all 12 (note
      `Feburary` — misspelled in the enum itself; test the enum as
      written, don't "fix" the typo as a side effect of writing a test)
- [ ] `WeekNumberExtension.value` — `First`..`Fourth` (1-4) and `Last`
      (-1, the one non-sequential value)
- [ ] `IntExtensions.getDayOfWeekEnumValue` — round-trip every valid int
      (0-6) back through `DayOfWeekExtension.value`, plus one
      out-of-range int to pin down the `default` fallback behavior
- [ ] Same round-trip pattern for `getMonthOfYearEnumValue` (1-12) and
      `getWeekNumberEnumValue` (1-4, -1) — these switches take `int`
      input over a non-exhaustive type, so their `default` branches are
      real, reachable fallback behavior; pin it down with an
      out-of-range-int case for each
  - **resolved:** the *other* direction (`DayOfWeekExtension.value`,
    `MonthOfYearExtension.value`, `WeekNumberExtension.value` — enum→int,
    exhaustively switched over a closed enum type) had 3 provably-dead
    `default` branches; these were already deleted (commit `f806ea1`,
    part of the `flutter analyze` 52→0 cleanup) on the strength of the
    compiler's own exhaustiveness proof, which is a stronger guarantee
    than a runtime test would have given — no test needed to justify
    that deletion after the fact. The round-trip tests above for
    `.value`/`.enumToString` are still worth writing as plain regression
    coverage; there's just no more "should we delete the default"
    decision attached to them.
- [ ] `AvailabilityExtensions.enumToString` — all 4 (`Busy`→`BUSY`,
      `Free`→`FREE`, `Tentative`→`TENTATIVE`, `Unavailable`→`UNAVAILABLE`)
- [ ] `EventStatusExtensions.enumToString` — all 4
- [ ] `CalendarAccessLevelExtensions.enumToString` — both (already
      covered indirectly via `RequestPermissions_*` tests; add one direct
      unit test here too since the extension is public API on its own)

### `lib/src/device_calendar.dart` — `DeviceCalendarPlugin` (expand existing coverage)
- [ ] `RequestPermissions_PlatformException_MapsToResultError` (currently
      only the success path is tested)
- [ ] `HasPermissions_Failure_ReturnsFalseResult`
- [ ] `RetrieveCalendars_EmptyList_ReturnsEmptyNotNull`
- [ ] `RetrieveCalendars_MalformedJson_ReturnsGenericErrorNotCrash` —
      real gap: `json.decode` inside `evaluateResponse` throws
      `FormatException`, which is neither `ArgumentError` nor
      `PlatformException`, so it falls through to
      `_parsePlatformExceptionAndUpdateResult`'s generic-`Exception`
      branch. Confirm that's actually what happens (don't assume) and
      pin it down.
- [ ] `RetrieveEvents_EventIdsOnly_SkipsDateValidation`
- [ ] `RetrieveEvents_NoEventIdsNoDates_Invalid`
- [ ] `RetrieveEvents_OnlyStartDate_Invalid`
- [ ] `RetrieveEvents_StartAfterEnd_Invalid`
- [ ] `RetrieveEvents_ValidDateRange_PassesMillisecondArgs`
- [ ] `RetrieveEvents_SuccessResponse_ParsesEventList`
- [ ] `DeleteEventInstance_*` — **zero coverage today.** At minimum:
      `AllArgsProvided_PassesThroughCorrectly`,
      `CalendarIdMissing_Invalid`, `EventIdMissing_Invalid`
- [ ] `CreateOrUpdateEvent_NullEvent_ReturnsNull`
- [ ] `CreateOrUpdateEvent_AllDay_CalendarIdEmpty_UsesAllDayErrorMessage`
      vs `CreateOrUpdateEvent_NonAllDay_StartAfterEnd_UsesNonAllDayErrorMessage`
      — these are two *different* error message constants
      (`createOrUpdateEventInvalidArgumentsMessageAllDay` vs.
      `createOrUpdateEventInvalidArgumentsMessage`); a test that only
      checks "is it invalid" without checking *which* message would miss
      a regression that silently swaps them
- [ ] `CreateOrUpdateEvent_AllDay_NormalizesStartEndToMidnight_NonAndroid`
      — this normalization is a **side effect inside the validation
      closure**, mutating `event.start`/`event.end` before
      `event.toJson()` is called for the channel arguments. High-value,
      currently completely untested. The `Platform.isAndroid` branch is
      untestable as pure Dart on a non-Android test host — either accept
      it as integration-test-only coverage (document that explicitly in
      the test file) or, better: ask before refactoring — extracting this
      normalization into a small `_normalizeAllDayBounds(bool isAndroid,
      ...)` free function would make both branches unit-testable with
      zero behavior change, but it's a source change beyond "just add
      tests," flag it rather than doing it silently.
- [ ] `CreateCalendar_NameNullOrEmpty_Invalid`
- [ ] `CreateCalendar_ColorNull_DefaultsToRed`
- [ ] `CreateCalendar_LocalAccountNameEmpty_DefaultsToDeviceCalendar`
- [ ] `DeleteCalendar_Success`/`DeleteCalendar_CalendarIdInvalid`
- [ ] `ShowIosEventModal_PassesEventIdArgument`
- [ ] `RetrieveEventColors_NonAndroid_ReturnsNullWithoutChannelCall` —
      assert the mocked channel log stays empty, not just that the
      return value is null
- [ ] `RetrieveEventColors_NullAccountName_ReturnsEmptyWithoutChannelCall`
- [ ] `RetrieveEventColors_Success_MapsColorPairs`
- [ ] Same three shapes for `RetrieveCalendarColors`
- [ ] `UpdateCalendarColor_CalendarIdNull_ReturnsFalseWithoutChannelCall`
- [ ] `UpdateCalendarColor_BothColorArgsNull_ReturnsFalseWithoutChannelCall`
- [ ] `UpdateCalendarColor_Success_UpdatesLocalCalendarColorField`
- [ ] `UpdateCalendarColor_Failure_ReturnsFalse`
- [ ] `InvokeChannelMethod_PlatformException_MapsToResultErrorWithCodeAndMessage`
- [ ] `InvokeChannelMethod_GenericException_MapsToGenericResultError`

## 2. Android native (`android/src/main/kotlin`) — needs setup first, but the toolchain itself is confirmed working

The Android build was modernized and re-verified since this plan was
first written (`flutter build apk --debug` succeeds in this environment
now — see the note at the top of this file). That was the actual blocker;
the setup below is just normal Gradle test-source-set plumbing, not a
toolchain gamble.

**Setup (do this before any Android test case above the line runs):**
- [ ] Add `android/src/test/kotlin/...` source set
- [ ] Add to `android/build.gradle.kts`:
      `testImplementation("junit:junit:4.13.2")`,
      `testImplementation("org.robolectric:robolectric:<latest>")`,
      `testImplementation("org.mockito.kotlin:mockito-kotlin:<latest>")`
      (for the few places a plain interaction-verifying mock is cleaner
      than a Robolectric shadow, e.g. verifying `contentResolver.insert`
      was called with specific `ContentValues`). Note this is the
      *plugin's own* `android/build.gradle.kts` — the `junit`/
      `androidx.test`/`espresso-core` deps already present in
      `example/android/app/build.gradle.kts` are unrelated template
      boilerplate for the example app's own instrumented tests, not
      something the plugin's unit tests can piggyback on.
- [ ] Run `./gradlew testDebugUnitTest` once the above is in place to
      confirm it resolves and executes (a plain, fast sanity check now
      that the underlying AGP/Gradle/Kotlin versions are known-good —
      not the open-ended toolchain question this bullet used to be).

### `CalendarDelegate.kt` — pure/near-pure functions (Robolectric not even required for some of these — plain JUnit)
- [ ] `BuildRecurrenceRuleParams_*` — one test per `Frequency` value
      (Daily/Weekly/Monthly/Yearly), then combinations: `interval`,
      `count`, `until`, single `byday`, multiple `byday` with
      occurrence numbers (e.g. "2nd Tuesday"), `bymonthday` single and
      multiple, `byyearday`, `byweekno`, `bymonth`, `bysetpos`, and at
      least one "everything set at once" case
- [ ] `BuildDurationString_*` — zero duration (all components 0 →
      null/empty per current behavior, pin down which), exactly 1 day,
      exactly 1 hour, exactly 1 second, mixed (1 day 2 hours 3 minutes 4
      seconds), and the exact boundary the code branches on (0 vs. 1 of
      each component) — this function is shared by both the normal
      event path and the new single-instance-exception path added this
      session, so a regression here silently breaks two features at once
- [ ] `GetAvailability_*` — all 4 `Availability` values incl. the
      `Unavailable → null` case (the null-safety bug fixed this session
      — this test is the regression guard for that fix; write it so it
      would have failed against the old `values.put(AVAILABILITY,
      getAvailability(...))` without the null check)
- [ ] `GetEventStatus_*` — all 4, incl. `EventStatus.None → null`
- [ ] `GetTimeZone_ValidName_ReturnsIt`,
      `GetTimeZone_InvalidName_FallsBackToDeviceTimeZone`,
      `GetTimeZone_Null_FallsBackToDeviceTimeZone`

### `CalendarDelegate.kt` — needs Robolectric `ShadowContentResolver`
- [ ] `GetOriginalSyncId_EventHasRrule_ReturnsSyncId`
- [ ] `GetOriginalSyncId_EventHasNoRrule_ReturnsNull`
- [ ] `GetOriginalSyncId_EventNotFound_ReturnsNull`
- [ ] `UpdateAttendees_NoExisting_InsertsAllNew`
- [ ] `UpdateAttendees_NoNew_DeletesAllExisting`
- [ ] `UpdateAttendees_SameSet_NoInsertsNoDeletes`
- [ ] `UpdateAttendees_PartialOverlap_InsertsAddedDeletesRemoved`
- [ ] `UpdateAttendees_SelfAttendeeStatusChanged_CallsUpdateAttendeeStatus`
- [ ] `UpdateAttendees_SelfAttendeeStatusUnchanged_DoesNotCallUpdateAttendeeStatus`
- [ ] `UpdateReminders_DeletesExistingThenInsertsNew`
- [ ] `CreateOrUpdateEvent_NewEvent_Inserts`
- [ ] `CreateOrUpdateEvent_ExistingEventNoOriginalInstanceTime_UpdatesWholeSeries`
- [ ] `CreateOrUpdateEvent_ExistingEventWithOriginalInstanceTime_RrulePresent_CreatesExceptionEvent`
      — regression coverage for this session's #428 extraction; assert
      the insert targets `Events.CONTENT_EXCEPTION_URI`, not
      `Events.CONTENT_URI`, and that `ORIGINAL_SYNC_ID`/
      `ORIGINAL_INSTANCE_TIME` are set correctly
- [ ] `CreateOrUpdateEvent_ExistingEventWithOriginalInstanceTime_NoRrule_UpdatesWholeSeriesNotException`
      — the not-actually-recurring case; must fall back to a normal
      update, not silently create a broken exception row
- [ ] `CreateOrUpdateEvent_ExceptionEvent_DurationFromNewStartToNewEnd_NotFromOriginalInstanceTime`
      — this is the exact bug fixed this session (mixing original start
      with new end); write the test with a start-time-shifted instance
      so it would catch a regression back to the buggy calculation
- [ ] `DeleteEvent_NoDatesNoFollowingInstances_DeletesAllInstances`
- [ ] `DeleteEvent_SingleInstanceOnly_CreatesCanceledException`
- [ ] `DeleteEvent_FollowingInstances_UpdatesRruleCount` — and the
      specific "no COUNT in original rule" vs. "has COUNT" branches
      already visible in the code around
      `EVENT_INSTANCE_DELETION_LAST_DATE_INDEX`
- [ ] `DeleteEventInstance_*` — same shape as `DeleteEvent`'s
      instance-deletion path
- [ ] `DeleteCalendar_Success`/`DeleteCalendar_Failure`
- [ ] `CreateCalendar_*`, `RetrieveCalendars_*`, `RetrieveEvents_*` (date
      range filtering, `eventIds` filtering), `RetrieveEventColors_*`,
      `RetrieveCalendarColors_*`, `UpdateCalendarColor_*` — mirror the
      Dart-layer test list above, but verifying the actual
      `ContentValues`/query built, not the channel arguments
- [ ] `RequestPermissions_AlreadyGranted_FinishesImmediately`,
      `RequestPermissions_NotGranted_CachesParametersAndRequests`
- [ ] `OnRequestPermissionsResult_Granted_ExecutesCachedAction` — one
      per `calendarDelegateMethodCode` branch in the `when`
- [ ] `OnRequestPermissionsResult_Denied_FinishesWithNotAuthorizedError`
- [ ] `OnRequestPermissionsResult_UnknownRequestCode_ReturnsFalse`

### `DeviceCalendarPlugin.kt`
- [ ] `ParseEventArgs_AllFieldsPresent_MapsCorrectly`
- [ ] `ParseEventArgs_OptionalFieldsMissing_NoCrash`
- [ ] `ParseEventArgs_OriginalInstanceTimeArgument_Mapped` (this
      session's addition — no coverage yet on the Kotlin side, only
      Dart's `toJson()` side is tested)
- [ ] `ParseRecurrenceRuleArgs_*` — same combinatorial coverage as the
      Dart-side `buildRecurrenceRuleParams` list above, mirrored for the
      *parsing* direction
- [ ] `OnMethodCall_*` — one test per method name routing to the correct
      delegate call, plus `OnMethodCall_UnknownMethod_NotImplemented`

### `AvailabilitySerializer.kt`, `EventStatusSerializer.kt`
- [ ] Gson round-trip (serialize then deserialize) for every enum value
      in each

### Models (`Attendee.kt`, `Calendar.kt`, `Event.kt`, `RecurrenceRule.kt`, `Reminder.kt`, `CalendarMethodsParametersCacheModel.kt`)
- [ ] Default-value construction test per class (these are plain data
      holders — one test each is enough unless a class has real logic,
      in which case treat it like `CalendarDelegate.kt` above)

## 3. iOS native (`ios/Classes/SwiftDeviceCalendarPlugin.swift`) — blocked here, write it anyway

No Xcode in this environment — none of this is runnable until whoever
picks this up has one. Write the target and the tests regardless; it's
still the highest-risk, least-covered layer (real bugs already found and
fixed here without any test net: #605's `let`→`var` compile bug, the
write-only permission gating design bug caught during this fork's own iOS
17 work).

**Setup:**
- [ ] Add `example/ios/RunnerTests/` XCTest target (standard Flutter iOS
      plugin unit test location) to `example/ios/Runner.xcodeproj`
- [ ] For anything touching `EKEventStore`: EventKit has no official
      mock. Two real choices, pick one deliberately rather than drifting:
      (a) wrap the handful of `EKEventStore` calls behind a small
      internal protocol and inject a fake in tests (real source change,
      ask before doing it broadly), or (b) accept EventKit-dependent
      logic is simulator/device-only and covered by `integration_test`
      instead, keeping XCTest for the pure-logic subset below. Given the
      size of this file (~1150 lines, one big class), (a) is a bigger
      lift than this plan should assume without sign-off — default to
      (b) unless told otherwise.

**Pure-logic subset, testable without any EventKit seam (extract into
free functions first if they're currently private methods on the plugin
class — same "don't silently refactor for testability" caveat as the
Dart `Platform.isAndroid` note above):**
- [ ] `HasEventPermissions_RequireFullAccess_*` and
      `HasEventPermissions_AllowWriteOnly_*` — for each
      `EKAuthorizationStatus` case (`.fullAccess`, `.writeOnly`,
      `.notDetermined`, `.denied`, `.restricted`, and the pre-iOS-17
      `.authorized`) crossed with `requireFullAccess: true/false`. This
      is the exact logic that had a real design bug caught during this
      session's iOS 17 work (write-only access briefly could've passed a
      full-access gate) — the highest-value test in this entire plan.
- [ ] `RequestPermissions_AccessLevelArgument_WriteOnlyString_RequestsWriteOnly`
      vs. `AnyOtherValue_RequestsFullAccess` — pure string-to-branch
      logic, no EventKit needed to test the *parsing*, only to test what
      happens after
- [ ] `BuildRecurrenceRuleParams`/RRULE string building — Swift-side
      equivalent of the Kotlin/Dart combinatorial list above
- [ ] `ParseRecurrenceRuleString` — inverse direction, including the
      blank-RRULE crash-prevention path (#608's fix, merged before this
      session started — currently has zero regression coverage on the
      Swift side)
- [ ] Event/Attendee/Reminder field-mapping helpers (whatever the
      to/from `EKEvent`/`EKParticipant`/`EKAlarm` conversion functions
      are called in this file) — attendee role/status enum mapping,
      availability/status enum mapping, error-message formatting
      (`finishWithEventNotFoundError` and friends)

**EventKit-dependent subset (simulator/device only, via `integration_test` — see section 5):**
- [ ] Full request-permissions flow end to end
- [ ] Create/update/delete event, single instance vs. whole series
- [ ] `showEventModal`/`EKEventViewDelegate` dismissal handling

## 4. Cross-language contract check — new, nothing like it exists today

- [ ] Write one script (Dart, run via `dart test` or as a plain
      `dart run` check — doesn't need `flutter_test`) that:
      1. Extracts every `private const val ..._ARGUMENT = "..."` string
         from `DeviceCalendarPlugin.kt`
      2. Extracts every `ChannelConstants.parameterName...` string from
         `lib/src/common/channel_constants.dart`
      3. Extracts every Swift argument-key string literal used for
         `call.arguments`/`arguments?[...]` lookups in
         `SwiftDeviceCalendarPlugin.swift`
      4. Asserts the three sets are identical
      This would have caught nothing that's currently broken (spot-
      checked `originalInstanceTime`, `calendarAccessLevel` — both match
      across all three), but it's exactly the kind of drift that a
      future one-line typo in any of the three files turns into a silent
      runtime failure instead of a compile error, in a codebase already
      shown (this session, #428/#502/#454) to accumulate stale/divergent
      branches easily.

## 5. Integration tests (`example/integration_test/`) — expand, device/simulator required

Current file covers: create event with title/description/location/url,
delete event, validation-error display. Add:
- [ ] Recurring event creation, verify RRULE round-trips via
      `retrieveEvents`
- [ ] Edit a single instance of a recurring event (this session's #428
      feature) — verify only that instance changes, the series' other
      instances don't
- [ ] Delete a single instance vs. delete all instances vs. delete
      following instances — verify calendar state after each
- [ ] Add/edit/remove attendee
- [ ] Add reminder
- [ ] All-day event creation and display (both single-day and, since
      #450, multi-day)
- [ ] Event color selection (Android-only path) and verification
- [ ] Permission-denial path — flag as likely needing platform-specific
      CI setup (`adb shell pm grant`/revoke for Android; a
      pre-authorized or explicitly-denied simulator state for iOS) rather
      than being freely automatable; document instead of skipping
      silently if it can't be wired up

## 6. Sequencing

Given the size of this list, the order that gets the most confidence per
hour of work, given what's actually runnable in this environment today:

1. **Dart unit tests (section 1).** Fully runnable right now, no
   toolchain gaps, directly extends the existing, working pattern.
   Biggest single gap closed: `createOrUpdateEvent`'s allDay
   normalization side effect and `deleteEventInstance`, both currently
   at zero coverage.
2. **Cross-language contract check (section 4).** Cheap, Dart-only,
   catches an entire class of bug the other layers can't catch each on
   their own.
3. **Android Robolectric setup + pure-function tests (section 2).**
   No longer a "try it and see" — the Gradle/AGP/Kotlin toolchain is
   now confirmed working in this environment (`flutter build apk
   --debug` succeeds). This moved up in priority since the last
   revision of this plan specifically because it went from speculative
   to a known-safe bet: the whole layer (50+ checklist items, currently
   at zero coverage, the largest gap in the entire repo) is runnable
   here today.
4. **Android Robolectric shadow-based tests** (the `ContentResolver`-
   dependent list) — same tooling as (3), just more setup per test.
5. **iOS XCTest target + pure-logic tests.** Write now regardless of
   this environment's Xcode gap (still present, untouched by the
   Android modernization work) — verify next time this is picked up
   somewhere with Xcode.
6. **Expanded `integration_test` coverage.** Needs a device/emulator
   either way; lowest priority not because it matters least, but
   because sections 1-4 catch more bugs per hour and don't need
   hardware.
