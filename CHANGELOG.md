# Changelog

## 3.2.0

* Added time zone support
* Project hierarchy update and clean up

## 3.1.0 25th March 2020 - Bug fixes and new features

* Boolean variable `isDefault` added for issue [145](https://github.com/builttoroam/device_calendar/issues/145) (**NOTE**: This is not supported Android API 16 or lower, `isDefault` will always be false)
* Events with 'null' title now defaults to 'New Event', issue [126](https://github.com/builttoroam/device_calendar/issues/126)
* Updated property summaries for issues [121](https://github.com/builttoroam/device_calendar/issues/121) and [122](https://github.com/builttoroam/device_calendar/issues/122)
* Updated example documentation for issue [119](https://github.com/builttoroam/device_calendar/issues/119)
* Read-only calendars cannot be edited or deleted for the example app
* Added `DayOfWeekGroup` enum and an extension `getDays` to get corresponding dates of the enum values
* Added to retrieve colour for calendars. Thanks to [nadavfima](https://github.com/nadavfima) for the contribution and PR to add colour support for both Android and iOS
* Added compatibility with a new Flutter plugin for Android. Thanks to the PR submitted by [RohitKumarMishra](https://github.com/RohitKumarMishra)
* [Android] Fixed all day timezone issue [164](https://github.com/builttoroam/device_calendar/issues/164)
* Added support for deleting individual or multiple instances of a recurring event for issue [108](https://github.com/builttoroam/device_calendar/issues/108)
* Ability to add local calendars with a desired colour for issue [115](https://github.com/builttoroam/device_calendar/issues/115)
* Returns account name and type for each calendars for issue [179](https://github.com/builttoroam/device_calendar/issues/179)

## 3.0.0+3 3rd February 2020

* Fixed all day conditional check for issue [162](https://github.com/builttoroam/device_calendar/issues/162)

## 3.0.0+2 30th January 2020

* Updated `event.allDay` property in `createOrUpdateEvent` method to be null-aware

## 3.0.0+1 28th January 2020

* Updated `event.url` property in `createOrUpdateEvent` method to be null-aware for issue [152](https://github.com/builttoroam/device_calendar/issues/152)

## 3.0.0 21st January 2020

* **BREAKING CHANGE** Properties for the attendee model in `attendee.dart` file have been changed:
  * Boolean property `isRequired` has been replaced to `AttendeeRole` enum
  * New arugment added for `AttendeeRole` property
* **BREAKING CHANGE** Package updates:
  * [Android] Updated Gradle plugin to 3.5.2 and Gradle wrapper to 5.4.1
  * [iOS] Updated Swift to 5
* `name` and `isOrganiser` (read-only) properties have been added
* Attendee UI update for the example app
* Ability to add, modify or remove an attendee

## 2.0.0 17th January 2020

* **BREAKING CHANGE** The recurrence models in `recurrence_rule.dart` file have been chaged
* **BREAKING CHANGE** All articles used in property names or arugments have been removed (i.e. enum `DayOfTheWeek` to `DayOfWeek`)
* Recurrence fix for monthly and yearly frequencies
* UI update for the example app
* Add support for all day events

## 1.0.0+3 9th January 2020

* Flutter upgrade to 1.12.13
* Added an URL input for calendar events for issue [132](https://github.com/builttoroam/device_calendar/issues/132)

## 1.0.0+2 30th August 2019

* Fix home page URL

## 1.0.0+1 30th August 2019

* Add integration tests to example app. Note that this is more for internal use at the moment as it currently requires an Android device with a calendar that can be written to and assumes that the tests are executed from a Mac.

## 1.0.0 28th August 2019

* **BREAKING CHANGE** `retrieveCalendars` and `retrieveEvents` now return lists that cannot be modified (`UnmodifiableListView`) to address part of  issue [113](https://github.com/builttoroam/device_calendar/issues/113)
* Support for more advanced recurrence rules
* Update README to include information about using ProGuard for issue [99](https://github.com/builttoroam/device_calendar/issues/99)
* Made event title optional to fix issue [72](https://github.com/builttoroam/device_calendar/issues/72)
* Return information about the organiser of the event as per issue [73](https://github.com/builttoroam/device_calendar/issues/73)
* Return attendance status of attendees and if they're required for an event. These are details are different across iOS and Android and so are returned within platform-specific objects
* Ability to modify attendees for an event
* Ability to create reminders for events expressed in minutes before the event starts

## 0.2.2 19th August 2019

* Add support for specifying the location of an event. Thanks to [oli06](https://github.com/oli06) and [zemanux](https://github.com/zemanux) for submitting PRs to add the functionality to iOS and Android respectively

## 0.2.1+1 5th August 2019

* Fixing date in changelog for version 0.2.1

## 0.2.1 5th August 2019

* [Android] Fixes issue [101](https://github.com/builttoroam/device_calendar/issues/101) where plugin results in a crash with headless execution

## 0.2.0 30th July 2019

* **BREAKING CHANGE** [Android] Updated to use Gradle plugin to 3.4.2, Gradle wrapper to 5.1.1, Kotlin version to 1.3.41 and bumped Android dependencies
* Add initial support for recurring events. Note that currently editing or deleting a recurring event will affect all instances of it. Future releases will look at supporting more advanced recurrence rules
* Remove old example app to avoid confusion

## 0.1.3 5th July 2019

* [iOS] Fixes issue [94](https://github.com/builttoroam/device_calendar/issues/94) that occurred on 32-bit iOS devices around date of events. Thanks to the PR submitted by [duzenko](https://github.com/duzenko)

## 0.1.2+2 28th May 2019

* Non-functional release. Minor refactoring in Android code to address issues found in Codefactor and fix build status badge in README

## 0.1.2+1 17th May 2019

* Non-functional release. Fixed formatting in changelog and code comments
* Added more info about potential issues in consuming the plugin within an Objective-C project

## 0.1.2 - 16th May 2019

* [Android] An updated fix to address issue [79](https://github.com/builttoroam/device_calendar/issues/79), thanks to the PR submitted by [Gerry High](https://github.com/gerryhigh)

## 0.1.1 - 1st March 2019

* Fixed issue [79](https://github.com/builttoroam/device_calendar/issues/79) where on Android, the plugin was indicating that it was handling permissions that it shouldn't have

## 0.1.0 - 26th February 2019

* **BREAKING CHANGE** Migrated to the plugin to use AndroidX instead of the deprecated Android support libraries. Please ensure you have migrated your application following the guide [here](https://developer.android.com/jetpack/androidx/migrate)
* **BREAKING CHANGE** Updated Kotlin to version 1.3.21
* **BREAKING CHANGE** Updated Gradle plugin to 3.3.1 and distribution to 4.10.2

## 0.0.8 - 26th February 2019

* This was a breaking change that should've been incremented as minor version update instead of a patch version update. See changelog for 0.1.0 for the details of this update

## 0.0.7 - 16th November 2018

* Fixes issue [##67](https://github.com/builttoroam/device_calendar/issues/67) and [##68](https://github.com/builttoroam/device_calendar/issues/68). Thanks to PR submitted by huzhiren.

## 0.0.6 - 18th June 2018

* [iOS] Fix an issue when adding/updating an event with a null description

## 0.0.5 - 14th June 2018

* [Android] Fixed an issue with retrieving events by id only

## 0.0.4 - 12th June 2018

* Reordering changelog
* Creating new example for the Pub Dart Example tab
* Moving existing example to the example_app GitHub folder

## 0.0.2 - 0.0.3 - 7th June 2018

* Fixing incorrect Travis build links

## 0.0.1 - 7th June 2018

* Ability to retrieve device calendars
* CRUD operations on calendar events
