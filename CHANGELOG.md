# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Bumped the minimum Flutter SDK constraint from `>=1.20.0` to `>=3.38.0`
- Migrated the Android build to Kotlin DSL (`build.gradle.kts`), matching Flutter's current plugin/app templates, and dropped the now-unnecessary AGP-version conditional this repo carried for the AGP 9 transition
- Bumped Android toolchain: Gradle 7.3/8.9 → 9.6.1, Android Gradle Plugin 4.1.3 → 9.2.0, Kotlin 1.8.22 → 2.3.20, `compileSdk` → 36, `minSdk` → 24
- Bumped Android dependencies: `gson` 2.8.8 → 2.14.0, `androidx.appcompat` 1.3.1 → 1.7.1, `kotlinx-coroutines-android` 1.5.0 → 1.10.2, `org.dmfs:lib-recur` 0.12.2 → 0.17.1
- Bumped the iOS deployment target from 8.0 to 13.0 and filled in the podspec's placeholder metadata (summary/description/homepage/author)
- Replaced the deprecated `Color.value` getter with `Color.toARGB32()`
- Replaced the deprecated `@required` annotation with the built-in `required` keyword
- Updated this changelog to the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) v1.1.0 format

### Fixed

- Fixed CI workflows (`release.yml`, `prerelease.yml`) invoking a reusable GitHub Actions workflow via a step-level `uses:`, which is only valid at the job level and had been silently broken
- Fixed the iOS CI job pinned to the retired `macos-13` runner image (moved to `macos-latest`)
- Fixed dead `default` branches in exhaustive enum `switch` statements flagged as unreachable by the analyzer

### Removed

- Removed the `mindsers/changelog-reader-action` CI dependency, replaced with a one-line `grep`/`awk`
- Removed `android.enableJetifier` (no longer needed; all dependencies are AndroidX-native)

## [4.3.3] - 2024-09-29

### Fixed

- Fixed an [issue](https://github.com/builttoroam/device_calendar/issues/490) that prevented the plugin from being used with iOS 17+

## [4.3.2] - 2023-11-08

### Removed

- Removed unnecessary package to reduce build error

## [4.3.1] - 2023-03-12

### Fixed

- Fixed an [issue](https://github.com/builttoroam/device_calendar/issues/470) that prevented the plugin from being used with Kotlin 1.7.10

## [4.3.0] - 2023-01-20

### Added

- Added support for all-day multi-day events on iOS

### Changed

- Updated multiple underlying dependencies
  - *Note:* `timezone 0.9.0` [removed named database files](https://pub.dev/packages/timezone/changelog#090). If you are only using `device_calendar`, you can ignore this note.

### Fixed

- Fixed iOS issue of adding attendees to events
- Fixed Android issue of the `ownerAccount` being null

## [4.2.0] - 2022-02-20

### Added

- Support for viewing and editing attendee status
  - iOS needs a specific native view and permissions to edit attendees due to iOS restrictions. See README and example app.

### Fixed

- Fix: apks can be build correctly now

## [4.1.0] - 2021-12-29

### Added

- Android: proper support for all day events, and multi-day all day events.

### Changed

- Integration tests are now working. Android instructions are ready.
- Gradle plug-ins are updated.
- Compiles with jvm 1.8, should be compilable for Flutter 2.9+

### Fixed

- Fix: title, descriptions etc are now retrieved properly.
- Fix: Event JSONs created and are now readable. Previous (mislabeled) JSONs are also readable with warnings.
- Fix: removed depreceated plugins from Example.

## [4.0.1] - 2021-12-04

### Fixed

- Fix: event time are now properly retrieved

## [4.0.0] - 2021-11-29

### Added

- Timezone plugin and logic implemented. All issues related to timezone shoulde be fixed.
- Events parameter now includes location and url. [319](https://github.com/builttoroam/device_calendar/pull/319)

### Changed

- Events.availability defaults to busy when not specified [354](https://github.com/builttoroam/device_calendar/pull/354)
- Android: Updated to V2 embeddding [326](https://github.com/builttoroam/device_calendar/issues/326)
- iOS: Updated swift versions, possibly improved compability with Obj-C [flutter/flutter#16049 (comment)](https://github.com/flutter/flutter/issues/16049#issuecomment-611192738)

### Fixed

- Android: Fixed bug where platform exception appeared, when Events.availability was null on Event [241](https://github.com/builttoroam/device_calendar/issues/241)
- Fixed various issues in example [270](https://github.com/builttoroam/device_calendar/issues/270), [268](https://github.com/builttoroam/device_calendar/issues/268)
- Android: deleteEvent code aligned with flutter [258](https://github.com/builttoroam/device_calendar/issues/258)

## [3.9.0] - 2021-11-26

### Changed

- Migrated to null safety
- Updated multiple underlying dependencies
- Rebuilt iOS podfile
- Upgraded to new Android plugins APIs for flutter

## [3.1.0] - 2020-03-25

### Added

- Boolean variable `isDefault` added for issue [145](https://github.com/builttoroam/device_calendar/issues/145) (**NOTE**: This is not supported Android API 16 or lower, `isDefault` will always be false)
- Added `DayOfWeekGroup` enum and an extension `getDays` to get corresponding dates of the enum values
- Added to retrieve colour for calendars. Thanks to [nadavfima](https://github.com/nadavfima) for the contribution and PR to add colour support for both Android and iOS
- Added compatibility with a new Flutter plugin for Android. Thanks to the PR submitted by [RohitKumarMishra](https://github.com/RohitKumarMishra)
- Added support for deleting individual or multiple instances of a recurring event for issue [108](https://github.com/builttoroam/device_calendar/issues/108)
- Ability to add local calendars with a desired colour for issue [115](https://github.com/builttoroam/device_calendar/issues/115)
- Returns account name and type for each calendars for issue [179](https://github.com/builttoroam/device_calendar/issues/179)

### Changed

- Updated property summaries for issues [121](https://github.com/builttoroam/device_calendar/issues/121) and [122](https://github.com/builttoroam/device_calendar/issues/122)
- Updated example documentation for issue [119](https://github.com/builttoroam/device_calendar/issues/119)

### Fixed

- Events with 'null' title now defaults to 'New Event', issue [126](https://github.com/builttoroam/device_calendar/issues/126)
- Read-only calendars cannot be edited or deleted for the example app
- [Android] Fixed all day timezone issue [164](https://github.com/builttoroam/device_calendar/issues/164)

## [3.0.0+3] - 2020-02-03

### Fixed

- Fixed all day conditional check for issue [162](https://github.com/builttoroam/device_calendar/issues/162)

## [3.0.0+2] - 2020-01-30

### Changed

- Updated `event.allDay` property in `createOrUpdateEvent` method to be null-aware

## [3.0.0+1] - 2020-01-28

### Changed

- Updated `event.url` property in `createOrUpdateEvent` method to be null-aware for issue [152](https://github.com/builttoroam/device_calendar/issues/152)

## [3.0.0] - 2020-01-21

### Added

- `name` and `isOrganiser` (read-only) properties have been added
- Ability to add, modify or remove an attendee

### Changed

- **BREAKING CHANGE** Properties for the attendee model in `attendee.dart` file have been changed:
  - Boolean property `isRequired` has been replaced to `AttendeeRole` enum
  - New arugment added for `AttendeeRole` property
- **BREAKING CHANGE** Package updates:
  - [Android] Updated Gradle plugin to 3.5.2 and Gradle wrapper to 5.4.1
  - [iOS] Updated Swift to 5
- Attendee UI update for the example app

## [2.0.0] - 2020-01-17

### Added

- Add support for all day events

### Changed

- **BREAKING CHANGE** The recurrence models in `recurrence_rule.dart` file have been chaged
- **BREAKING CHANGE** All articles used in property names or arugments have been removed (i.e. enum `DayOfTheWeek` to `DayOfWeek`)
- UI update for the example app

### Fixed

- Recurrence fix for monthly and yearly frequencies

## [1.0.0+3] - 2020-01-09

### Added

- Added an URL input for calendar events for issue [132](https://github.com/builttoroam/device_calendar/issues/132)

### Changed

- Flutter upgrade to 1.12.13

## [1.0.0+2] - 2019-08-30

### Fixed

- Fix home page URL

## [1.0.0+1] - 2019-08-30

### Added

- Add integration tests to example app. Note that this is more for internal use at the moment as it currently requires an Android device with a calendar that can be written to and assumes that the tests are executed from a Mac.

## [1.0.0] - 2019-08-28

### Added

- Support for more advanced recurrence rules
- Return information about the organiser of the event as per issue [73](https://github.com/builttoroam/device_calendar/issues/73)
- Return attendance status of attendees and if they're required for an event. These are details are different across iOS and Android and so are returned within platform-specific objects
- Ability to modify attendees for an event
- Ability to create reminders for events expressed in minutes before the event starts

### Changed

- **BREAKING CHANGE** `retrieveCalendars` and `retrieveEvents` now return lists that cannot be modified (`UnmodifiableListView`) to address part of issue [113](https://github.com/builttoroam/device_calendar/issues/113)
- Update README to include information about using ProGuard for issue [99](https://github.com/builttoroam/device_calendar/issues/99)

### Fixed

- Made event title optional to fix issue [72](https://github.com/builttoroam/device_calendar/issues/72)

## [0.2.2] - 2019-08-19

### Added

- Add support for specifying the location of an event. Thanks to [oli06](https://github.com/oli06) and [zemanux](https://github.com/zemanux) for submitting PRs to add the functionality to iOS and Android respectively

## [0.2.1+1] - 2019-08-05

### Fixed

- Fixing date in changelog for version 0.2.1

## [0.2.1] - 2019-08-05

### Fixed

- [Android] Fixes issue [101](https://github.com/builttoroam/device_calendar/issues/101) where plugin results in a crash with headless execution

## [0.2.0] - 2019-07-30

### Added

- Add initial support for recurring events. Note that currently editing or deleting a recurring event will affect all instances of it. Future releases will look at supporting more advanced recurrence rules

### Changed

- **BREAKING CHANGE** [Android] Updated to use Gradle plugin to 3.4.2, Gradle wrapper to 5.1.1, Kotlin version to 1.3.41 and bumped Android dependencies

### Removed

- Remove old example app to avoid confusion

## [0.1.3] - 2019-07-05

### Fixed

- [iOS] Fixes issue [94](https://github.com/builttoroam/device_calendar/issues/94) that occurred on 32-bit iOS devices around date of events. Thanks to the PR submitted by [duzenko](https://github.com/duzenko)

## [0.1.2+2] - 2019-05-28

### Changed

- Non-functional release. Minor refactoring in Android code to address issues found in Codefactor and fix build status badge in README

## [0.1.2+1] - 2019-05-17

### Added

- Added more info about potential issues in consuming the plugin within an Objective-C project

### Fixed

- Non-functional release. Fixed formatting in changelog and code comments

## [0.1.2] - 2019-05-16

### Fixed

- [Android] An updated fix to address issue [79](https://github.com/builttoroam/device_calendar/issues/79), thanks to the PR submitted by [Gerry High](https://github.com/gerryhigh)

## [0.1.1] - 2019-03-01

### Fixed

- Fixed issue [79](https://github.com/builttoroam/device_calendar/issues/79) where on Android, the plugin was indicating that it was handling permissions that it shouldn't have

## [0.1.0] - 2019-02-26

### Changed

- **BREAKING CHANGE** Migrated to the plugin to use AndroidX instead of the deprecated Android support libraries. Please ensure you have migrated your application following the guide [here](https://developer.android.com/jetpack/androidx/migrate)
- **BREAKING CHANGE** Updated Kotlin to version 1.3.21
- **BREAKING CHANGE** Updated Gradle plugin to 3.3.1 and distribution to 4.10.2

## [0.0.8] - 2019-02-26

### Changed

- This was a breaking change that should've been incremented as minor version update instead of a patch version update. See changelog for 0.1.0 for the details of this update

## [0.0.7] - 2018-11-16

### Fixed

- Fixes issue [##67](https://github.com/builttoroam/device_calendar/issues/67) and [##68](https://github.com/builttoroam/device_calendar/issues/68). Thanks to PR submitted by huzhiren.

## [0.0.6] - 2018-06-18

### Fixed

- [iOS] Fix an issue when adding/updating an event with a null description

## [0.0.5] - 2018-06-14

### Fixed

- [Android] Fixed an issue with retrieving events by id only

## [0.0.4] - 2018-06-12

### Added

- Creating new example for the Pub Dart Example tab

### Changed

- Reordering changelog
- Moving existing example to the example_app GitHub folder

## [0.0.3] - 2018-06-07

Also covers 0.0.2, which was released the same day.

### Fixed

- Fixing incorrect Travis build links

## [0.0.1] - 2018-06-07

### Added

- Ability to retrieve device calendars
- CRUD operations on calendar events

[Unreleased]: https://github.com/builttoroam/device_calendar/compare/4.3.3...HEAD
[4.3.3]: https://github.com/builttoroam/device_calendar/compare/4.3.2...4.3.3
[4.3.2]: https://github.com/builttoroam/device_calendar/compare/4.3.1...4.3.2
[4.3.1]: https://github.com/builttoroam/device_calendar/compare/4.3.0...4.3.1
[4.3.0]: https://github.com/builttoroam/device_calendar/compare/4.2.0...4.3.0
[4.2.0]: https://github.com/builttoroam/device_calendar/compare/4.1.0...4.2.0
[4.1.0]: https://github.com/builttoroam/device_calendar/compare/4.0.1...4.1.0
[4.0.1]: https://github.com/builttoroam/device_calendar/compare/4.0.0...4.0.1
[4.0.0]: https://github.com/builttoroam/device_calendar/compare/3.9.0...4.0.0
[3.9.0]: https://github.com/builttoroam/device_calendar/compare/v3.1.0...3.9.0
[3.1.0]: https://github.com/builttoroam/device_calendar/compare/v3.0.0+3...v3.1.0
[3.0.0+3]: https://github.com/builttoroam/device_calendar/compare/v3.0.0+2...v3.0.0+3
[3.0.0+2]: https://github.com/builttoroam/device_calendar/compare/v3.0.0+1...v3.0.0+2
[3.0.0+1]: https://github.com/builttoroam/device_calendar/compare/v3.0.0...v3.0.0+1
[3.0.0]: https://github.com/builttoroam/device_calendar/compare/v2.0.0...v3.0.0
[2.0.0]: https://github.com/builttoroam/device_calendar/compare/v1.0.0+3...v2.0.0
[1.0.0+3]: https://github.com/builttoroam/device_calendar/compare/v1.0.0+2...v1.0.0+3
[1.0.0+2]: https://github.com/builttoroam/device_calendar/compare/v1.0.0+1...v1.0.0+2
[1.0.0+1]: https://github.com/builttoroam/device_calendar/compare/v1.0.0...v1.0.0+1
[1.0.0]: https://github.com/builttoroam/device_calendar/compare/v0.2.2...v1.0.0
[0.2.2]: https://github.com/builttoroam/device_calendar/compare/v0.2.1+1...v0.2.2
[0.2.1+1]: https://github.com/builttoroam/device_calendar/compare/v0.2.1...v0.2.1+1
[0.2.1]: https://github.com/builttoroam/device_calendar/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/builttoroam/device_calendar/compare/v0.1.3...v0.2.0
[0.1.3]: https://github.com/builttoroam/device_calendar/compare/v0.1.2+2...v0.1.3
[0.1.2+2]: https://github.com/builttoroam/device_calendar/compare/v0.1.2+1...v0.1.2+2
[0.1.2+1]: https://github.com/builttoroam/device_calendar/compare/v0.1.2...v0.1.2+1
[0.1.2]: https://github.com/builttoroam/device_calendar/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/builttoroam/device_calendar/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/builttoroam/device_calendar/compare/v0.0.8...v0.1.0
[0.0.8]: https://github.com/builttoroam/device_calendar/compare/v0.0.7...v0.0.8
[0.0.7]: https://github.com/builttoroam/device_calendar/compare/v0.0.6...v0.0.7
[0.0.6]: https://github.com/builttoroam/device_calendar/compare/v0.0.5...v0.0.6
[0.0.5]: https://github.com/builttoroam/device_calendar/compare/v0.0.4...v0.0.5
[0.0.4]: https://github.com/builttoroam/device_calendar/compare/v0.0.2-0.0.3...v0.0.4
[0.0.3]: https://github.com/builttoroam/device_calendar/compare/v0.0.1...v0.0.2-0.0.3
[0.0.1]: https://github.com/builttoroam/device_calendar/releases/tag/v0.0.1
