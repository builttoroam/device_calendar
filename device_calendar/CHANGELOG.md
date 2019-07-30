# 0.2.0 30th July 2019
* Add initial support for recurring events. Note that currently editing or deleting a recurring event will affect all instances of it. Future releases will look at supporting more advanced recurrence rules
* **BREAKING CHANGE** [Android] Updated to use Gradle plugin to 3.4.2, Gradle wrapper to 5.1.1, Kotlin version to 1.3.41 and bumped Android dependencies
* Remove old example app to avoid confusion

# 0.1.3 5th July 2019
* [iOS] Fixes issue [94](https://github.com/builttoroam/flutter_plugins/issues/94) that occurred on 32-bit iOS devices around date of events. Thanks to the PR submitted by [duzenko](https://github.com/duzenko)

# 0.1.2+2 28th May 2019
* Non-functional release. Minor refactoring in Android code to address issues found in Codefactor and fix build status badge in README

## 0.1.2+1 17th May 2019
* Non-functional release. Fixed formatting in changelog and code comments
* Added more info about potential issues in consuming the plugin within an Objective-C project

## 0.1.2 - 16th May 2019
* [Android] An updated fix to address issue [79](https://github.com/builttoroam/flutter_plugins/issues/79), thanks to the PR submitted by [Gerry High](https://github.com/gerryhigh)

## 0.1.1 - 1st March 2019
* Fixed issue [79](https://github.com/builttoroam/flutter_plugins/issues/79) where on Android, the plugin was indicating that it was handling permissions that it shouldn't have

## 0.1.0 - 26th February 2019
* **BREAKING CHANGE** Migrated to the plugin to use AndroidX instead of the deprecated Android support libraries. Please ensure you have migrated your application following the guide [here](https://developer.android.com/jetpack/androidx/migrate)
* **BREAKING CHANGE** Updated Kotlin to version 1.3.21
* **BREAKING CHANGE** Updated Gradle plugin to 3.3.1 and distribution to 4.10.2

## 0.0.8 - 26th February 2019

* This was a breaking change that should've been incremented as minor version update instead of a patch version update. See changelog for 0.1.0 for the details of this update

## 0.0.7 - 16th November 2018
* Fixes issue [#67](https://github.com/builttoroam/flutter_plugins/issues/67) and [#68](https://github.com/builttoroam/flutter_plugins/issues/68). Thanks to PR submitted by huzhiren.

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
