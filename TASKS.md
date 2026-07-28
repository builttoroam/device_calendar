# device_calendar fork revival — task list & plan

**For any agent picking this up**: read this whole file before touching
anything. It's the source of truth for what's done, what's left, and the
ground rules for doing it right. Update it as you go — check off items,
add findings, correct anything that turns out wrong.

## Why this fork exists

`builttoroam/device_calendar` (pub.dev: `device_calendar`) is the most
widely-used Flutter plugin for native device calendar read/write (279
pub.dev likes), but it's effectively unmaintained: last commit merged
2025-03-08, 118 open issues, PRs sitting unreviewed for years (oldest
open PR here dates to 2020).

Owner (bencouture) wants to:
1. Revive it: review and merge the good open PRs, fix what's broken in
   them, reject what's stale/bad.
2. Add iOS 17 split full/write-only calendar permission support (a real
   gap — the original reason a different plugin, `device_calendar_plus`,
   was considered instead, before a worse bug was found there — see
   "Why not device_calendar_plus" below).
3. Publish the result to pub.dev under bencouture's account as a real,
   independently-usable package (not a git-URL dependency).
4. Point the Vikunja Flutter app's calendar-sync feature at it.

### Why not device_calendar_plus or eventide instead

Investigated as alternatives before choosing to revive `device_calendar`:

- **`device_calendar_plus`**: has a real, confirmed bug — `deleteEvent`
  on Android uses `CALLER_IS_SYNCADAPTER=true`, which makes deletions
  disappear locally but never propagates them to the remote account
  (Google Calendar), so deleted events silently reappear on next sync.
  Root-caused via the plugin's own PR #59 history. Closed to outside
  PRs (issue-only, per their CONTRIBUTING.md).
- **`eventide`**: no bugs found, but small (26 likes) and the owner
  wants to contribute to something more widely used instead.
- **`device_calendar`**: most widely used, and its own delete
  implementation is a plain `contentResolver.delete()` — does **not**
  have the device_calendar_plus bug. Its problems are staleness and a
  missing iOS 17 write-only permission tier, both fixable.

## Repo / remote setup

- Fork: `https://github.com/bencouture/device_calendar` (forked from
  `builttoroam/device_calendar`)
- Local clone: `/home/ben/git/device_calendar`
- Remotes: `origin` = the fork (push here), `upstream` =
  `builttoroam/device_calendar` (read-only, PR source)
- Working branch: `develop` (matches upstream's default branch)
- All work so far is **pushed to `origin/develop`**.

## Ground rules (read before reviewing any more PRs)

1. **No blind merges.** Every PR gets a real code review: read the full
   diff against its actual merge-base (not against a possibly-stale
   `develop` tip — use `git merge-base develop pr-XXX` first, PR diffs
   shown by `gh pr view` against current `develop` can show unrelated
   phantom changes if the PR branch predates other merges).
2. **CI signal on this repo is useless.** Every check on every PR here
   either times out waiting 24h for a runner that's never available, or
   hits transient infra failures (e.g. a 502 fetching Gradle's zip).
   Verified this directly (PR #612's CI logs). Don't trust green/red CI
   status at all — review and verify manually instead.
3. **Verify, don't assume a PR's stated diff is safe.** Two real bugs
   were found this way so far:
   - #605 didn't compile (reassigned a Swift `let` property).
   - #604 bumped `timezone` to a version requiring Dart SDK `^3.10.0`
     without updating this package's own SDK constraint (was
     `<3.0.0`), which would've broken `pub get` entirely.
   Run `flutter pub get` and `flutter analyze lib/` after every Dart/
   pubspec change — both are available at `~/develop/flutter/bin/flutter`
   on this machine. **There is no Swift/Xcode toolchain here** — iOS
   native changes can only be reasoned about carefully, not
   compile-verified. Say so explicitly in commit messages when a change
   isn't build-verified.
4. **Always attribute the original PR author.** Two ways depending on
   whether their commit is used as-is or rewritten:
   - If merging their commit directly (`git merge --no-ff pr-XXX`),
     git preserves their authorship automatically — nothing extra
     needed.
   - If you rewrite their fix (because it had a bug, or you're
     extracting only part of a larger PR), get their name/email via
     `git log --format="%an <%ae>" -1 pr-XXX`, then commit with
     `git commit --author="Name <email>"` while you remain the
     committer. Say in the commit body what was wrong with the
     original and what you changed. See commits `8c2cd01`, `9982630`,
     `f82ff0c` for the pattern.
   - Never use `git rebase -i` (interactive rebase needs a human at a
     terminal, not supported in an agent session). To fix earlier
     commit messages/authorship on this branch (nothing's been merged
     upstream, so history here is still safely rewritable), use
     `git reset --soft <commit-before>` and recommit cleanly instead —
     see this repo's own reflog around commits `8c2cd01`/`9982630` for
     a worked example of exactly this.
5. **A PR can be correct-in-isolation but still not mergeable.** If it
   bundles unrelated changes, conflicts against clean `upstream/develop`
   already, or is based on a wildly stale snapshot, don't force it —
   extract just the genuinely-needed pieces by hand (see PR #587's
   handling) or skip it with a clear written reason (see #603, #578,
   #575, #552).
6. **A PR's stated fix can already be superseded.** Diff against the
   TRUE merge-base every time — #603's "fix" turned out to be a no-op
   because the real fix had already landed on `develop` independently
   by the time this review happened.
7. **Publishing to pub.dev is a real, external, hard-to-undo action.**
   Do not run `dart pub publish` without explicit confirmation from
   bencouture immediately beforehand, even if everything else on this
   list is done and this file says it's "ready."

## Status: done

All pushed to `origin/develop`.

- [x] Forked repo, cloned locally, `upstream` remote added
- [x] **#612** AGP 9.x compatibility — merged, no bugs found
- [x] **#608** blank RRULE crash fix — merged, no bugs found
- [x] **#605** iOS retrieve-events-after-permission-grant fix — merged
      **with a fix**: didn't compile as submitted (`let` → `var` on
      `eventStore`). Author credited (mhamdanx).
- [x] **#604** timezone → 0.11.0 — merged **with a fix**: added the
      missing Dart SDK constraint bump (`>=3.10.0 <4.0.0`) the PR
      needed but didn't include. This PR's own diff already included
      #594's exact fix (see below). Author credited (Maurizio Pinotti).
- [x] **#603** status null-check reintroduction — reviewed, **skipped**:
      diff against true merge-base is a no-op reorder; the actual fix
      was already independently present on `develop`.
- [x] **#594** full URL vs data URI — **not merged separately**,
      byte-for-byte identical to a change already bundled inside #604.
      Nothing left to do here.
- [x] **#587** Gradle config for modern Android — reviewed, **rejected
      as a whole** (conflicts against clean upstream, bundles unrelated
      CI workflow rewrites and example-app changes, based on a very old
      snapshot where most of its other claims are already moot).
      Extracted by hand and merged: Java 17 compatibility bump, dropped
      deprecated `AndroidManifest.xml` `package` attribute. Author
      credited (crmado).
- [x] **#578, #575, #552** (iOS EKEventStore singleton/lazy-init
      variants) — investigated as possible sources for the iOS 17
      permission work below. **None merged**: none of them actually
      fix the underlying issue (#605 already does, correctly); #552's
      own linked issue is self-contradictory about why it "worked."
- [x] **iOS 17 split full/write-only permission support** — built from
      scratch (none of the reviewed PRs solved this). New
      `CalendarAccessLevel` enum (`full`/`writeOnly`),
      `requestPermissions(accessLevel:)`, iOS native
      `requestWriteOnlyAccessToEvents` wiring, Android needs no changes
      (silently ignores the new parameter, which is correct — Android
      has one permission tier). **Caught and fixed a real design bug
      before committing**: an early draft would have let a write-only
      grant pass the shared permission gate in front of read-requiring
      operations like `retrieveEvents`; fixed by making
      `hasEventPermissions()` default to strict/full-access and only
      relaxing it explicitly at the two call sites that should accept
      write-only. Not build-verified (no Xcode here).

## Status: remaining work

### 1. Two "superseded" claims made during initial triage, never actually verified — verify then close

These were guessed-superseded in the first pass based on title similarity
alone, unlike #594 (which was actually diffed and confirmed identical).
Confirm properly before crossing off:

- [x] **#590** "Upgrade to timezone 0.10.0" — **verified superseded,
      closed**. Diffed against true merge-base: timezone bump (goes to
      0.11.0 in the PR's own diff) and the `Uri.dataFromString` →
      `Uri.tryParse` event-url fix are both already on `develop` via
      #604. Remaining diff is noise: a stale gradle-wrapper distro
      bump (superseded by #612's AGP9 work), an accidentally-committed
      generated Xcode lldb ephemeral file, and an unrelated
      `flutter_lints: ^2.0.1` → `any` loosening not part of the PR's
      stated purpose (and `any` is worse practice — no upper bound at
      all). Nothing to merge.
- [x] **#580** "fix event url" — **verified NOT superseded by #594,
      reviewed and rejected**. Original triage guess was wrong: #580 is
      a materially different, broader change, not the same fix as
      #594/#604. #594/#604 only swapped `Uri.dataFromString` for
      `Uri.tryParse` while keeping `Event.url` typed as `Uri?`. #580
      instead changes `Event.url`'s type from `Uri?` to `String?`
      outright — a breaking public API change — and the underlying bug
      (`Uri.dataFromString` mishandling real URLs) is already fixed by
      the milder, non-breaking fix already on `develop`. #580 also
      bundles an unrelated Android native change in
      `CalendarDelegate.kt` (`Events.CUSTOM_APP_PACKAGE`) with no
      connection to the URL fix. Rejected as bundled + unnecessary
      breaking change, same reasoning as #587. Nothing to merge.

### 2. Remaining PRs needing a full individual review (13, not merged/decided yet)

Use the same review method as the completed ones above: fetch via
`git fetch upstream pull/<N>/head:pr-<N>`, diff against
`git merge-base develop pr-<N>`, read it fully, verify (pub get /
analyze for Dart changes; careful manual reasoning for native code),
then either merge with attribution, extract-and-merge the valid parts,
or skip with a clearly written reason — same as every item in the
"done" section above models.

Ordered newest-first (most likely to still be relevant first):

- [x] **#569** "Remove native ios event modal tool bar" (2024-11-13) —
      **merged** (`git merge --no-ff pr-569`), original triage worry
      was unfounded. Verified: the removed toolbar-styling lines in
      `showEventModal` (isTranslucent/tintColor/backgroundColor) styled
      a `UINavigationController.toolbar` that is never unhidden
      anywhere in this file (no `setToolbarHidden(false)` /
      `isToolbarHidden = false` call exists in the whole plugin) — it
      was dead code styling an invisible bar, not a visible-UI removal.
      Bundled with two other small, unrelated-but-safe fixes from the
      same PR: `showEventModal`'s event-not-found path now uses the
      existing `finishWithEventNotFoundError()` helper (the other 3
      call sites in the file already did; this was the inconsistent
      one), and the example app's "Attendees" button now passes the
      real `eventId` into `EventAttendeePage` (previously omitted, so
      its "View/edit iOS attendance details" button called
      `showiOSEventModal('')` with an empty id). Author credited
      (haowen737) via merge commit. Not build-verified (no Xcode).
- [x] **#531** "Fix: Update Set\<T\> to List\<T\> in calendar_event.dart
      to comply with rrule 0.2.16" (2024-03-17) — **verified superseded,
      closed**. Confirmed `develop`'s `pubspec.yaml` (`rrule: ^0.2.15`)
      resolves to `rrule` 0.2.18 (`flutter pub get`/lockfile), whose
      `RecurrenceRule.copyWith` already types `byWeekDays`/`byMonthDays`
      as `List`, and `example/lib/presentation/pages/calendar_event.dart`
      on `develop` already uses list literals (`[1]`, not `{1}`)
      everywhere — `flutter analyze` on that file has zero type errors.
      Diffing pr-531 against current `develop` (not just its stale
      merge-base) confirms why: the PR branch predates the event-color
      feature, the `flutter_timezone` migration, and the #569 eventId
      fix just merged above — applying it would be a net regression,
      not an update. Nothing to merge.
- [x] **#512** "namespace change" (2023-10-27) — **reviewed, rejected**.
      Not literally superseded (its actual content — guarding the
      `namespace 'com.builttoroam.devicecalendar'` line with
      `if (project.android.hasProperty("namespace"))` for AGP <4.2
      compatibility — isn't present on `develop` in any form), but the
      scenario it guards against can't occur: `android/build.gradle` on
      `develop` already requires `compileSdkVersion 34` and Java 17,
      both of which need AGP 7+ (namespace DSL was introduced in AGP
      7.0), so any consuming project already satisfying this plugin's
      other requirements necessarily has a namespace-capable AGP. The
      guard would only matter for an AGP <4.2 project, which couldn't
      build this plugin at all regardless. Skipped as defensive code
      for an impossible scenario, not because it's redundant with
      something already merged.
- [x] **#510** "rel" (2023-10-14, base: `master` not `develop`) —
      **reviewed, skipped**. Diffed against the true merge-base on
      `master` (not `develop` — confirms the title's base-branch note):
      the entire PR is a 4-line `pubspec.yaml` change — version
      `4.3.1` → `4.3.2`, drop the `homepage` field, add
      `publish_to: none`. This is upstream's own internal
      release-prep/version-bump housekeeping, not a bug fix or feature.
      `publish_to: none` would actively block the eventual `dart pub
      publish` this fork's project wants (section 5) — the opposite of
      what we need. Version/homepage/publish settings for this fork get
      decided fresh in "Prep for publishing" below, not inherited from
      here. Nothing to merge.
- [x] **#502** "test update" (2023-09-16) — **extracted and merged by
      hand**. Real content: extends
      `example/integration_test/app_test.dart` to fill and verify
      description/location/url fields (not just title) round-trip
      through save, plus matching `key: Key(...)` additions on those
      `TextFormField`s so the test can find them. The
      `calendar_event.dart` hunk didn't apply cleanly (file has moved
      on — event-color feature, `flutter_timezone` migration, #569's
      eventId fix) so it was hand-applied instead of merged; the test
      file itself applied clean. Also fixed a leftover unused-variable
      warning the original PR introduced (`saveEventButtonFinder`
      became dead after the rewrite switched to inline `keyFinder()`
      calls). `flutter analyze` clean on both files. Author credited
      (Thomas / thomassth). Not run against a device — needs a
      physical device + writable calendar per the test file's own
      header note.
- [x] **#471** "macOS support" (2023-02-09) — **skipped, out of scope**.
      Confirmed with bencouture: don't expand scope beyond what the
      downstream consumer (the Vikunja Flutter app at `/home/ben/git/app`)
      needs. That app has no `macos/` platform directory — it doesn't
      target macOS — so macOS support here isn't needed. Not reviewed
      in depth. Revisit if the downstream app ever adds a macOS target.
- [x] **#454** "Removed platform-specific logic from the example app."
      (2022-11-02) — **extracted and merged by hand**. Its own commit
      message explains the rationale: the example app hid the 'To'
      date picker for allDay events on non-Android platforms because
      iOS allDay events used to always be single-day; PR #450 added
      multi-day allDay support on both platforms, making that
      distinction stale. Verified #450 (merge commit `039f047`) really
      is already an ancestor of `develop`
      (`git merge-base --is-ancestor 039f047 develop`), so the premise
      holds today, not just at PR-open time. Didn't apply cleanly as a
      merge (file has moved on, same staleness as #531/#502/#580) so
      hand-applied instead. `flutter analyze` clean. Author credited
      (Julius Bredemeyer / IVLIVS-III).
- [x] **#448** "[5.0] rrule legacy layer" (2022-10-12, base: `develop`)
      and **#445** "5.0 prerelease" (2022-10-07, base: `release`) —
      **both reviewed, both skipped, confirmed abandoned effort**.
      - #448: diffs cleanly against `develop` (only 2 new files, 162
        lines), but adds a `RecurrenceRuleLegacy` class (a v4.x-API
        compatibility shim for the old custom `RecurrenceRule`, from
        before this repo's own `40b1135 Implementing Rrule package
        (#403)` migration) that is never referenced anywhere else in
        the diff — not wired into `Event`, not exported from
        `lib/device_calendar.dart`. Dead code, and speculative: nothing
        in this project's actual roadmap needs a 4.x-compat shim (the
        rrule migration already fully landed and nothing consumes the
        old API). Its own commit is literally titled "draft legacy
        layer". Skip.
      - #445: diffs against its true base (`release`, not `develop` —
        confirmed via `git merge-base upstream/release pr-445`) at
        ~2100 lines across 49 files — it's a wholesale snapshot from
        before the rrule migration, the event-color feature, and
        everything else currently on `develop`. Applying it would be a
        massive regression, not an update. Confirmed abandoned, same
        conclusion as the original triage guess, nothing to extract.
- [x] **#435** "Adding new features" (2022-08-25, base: `master`) —
      **reviewed, skipped**. Diffed against its true merge-base on
      `upstream/master`: ~2150 lines across 44 files, touching nearly
      every file in the repo (`CalendarDelegate.kt` alone: +1166/-...).
      Same generation and same problem as #445/#448 above — a snapshot
      old enough to predate the rrule migration, so applying it would
      revert large amounts of work already done independently on
      `develop` since. Too large and too stale to extract pieces from
      safely; no distinguishable individual feature worth pulling out
      by hand (title itself is vague — "Adding new features" — with no
      itemized list to check against current `develop`). Skip.
- [x] **#428** "Android recurring events, edit single instance"
      (2022-06-10) — **extracted and merged by hand**. Real, valuable
      feature: `Event.originalInstanceTime`, wired through so
      `createOrUpdateEvent` creates/updates a `CONTENT_EXCEPTION_URI`
      exception event instead of the whole recurring series when set —
      confirmed no overlap, this is the same pattern
      `deleteEventInstance` already uses for single-instance deletes,
      just for updates instead of deletes. PR branch predates the rrule
      migration so applying it whole would've regressed a lot; extracted
      by hand instead, with three real bugs fixed along the way rather
      than reproduced: (1) the original computed exception-event
      duration from `originalInstanceTime` → new end, which is wrong
      when an edit also moves the start time — now uses new start → new
      end, matching how the normal (non-exception) path already
      computes duration; (2) the original used `java.time.Duration`/
      `Instant`, which needs API 26+ or desugaring (neither present,
      minSdk 19) and would've crashed on older devices — reused this
      file's own existing `kotlin.time`-based duration builder instead
      (extracted into a shared `buildDurationString()` helper); (3)
      fixed a pre-existing, unrelated latent bug noticed while in this
      code: `Events.AVAILABILITY` was written from a nullable Int
      without a null check (unlike the adjacent `Events.STATUS` write),
      risking an NPE for `Availability.Unavailable`. Skipped the PR's
      own stale `build.gradle`/CI/README hunks (superseded by this
      repo's AGP9 modernization). Added
      `Event_OriginalInstanceTime_SerializesWriteOnly` to
      `test/device_calendar_test.dart` (16/16 pass). **Not
      build-verified**: discovered this environment's Android toolchain
      has its own pre-existing gap, separate from the iOS/Xcode one —
      `example/android`'s Gradle wrapper is a stale 7.3 from 2020,
      incompatible with whatever JDK Flutter resolves here (reports as
      class-file major version 65 / JDK 21); confirmed by reproducing
      the identical failure on a clean `develop` checkout with none of
      these changes applied, so it's an environment gap, not something
      this change caused. Worth fixing this Gradle/JDK mismatch before
      relying on Android build verification for future PR reviews in
      this project. Author credited (Karol Wrótniak).
- [x] **#419** "update mac support" (2022-04-16) — **skipped, out of
      scope**, same reasoning and same conversation as #471 above.
- [x] **#213** "change ios part - migration to Objective-c"
      (2020-03-31) — **confirmed obsolete, skipped**. Diff deletes
      `SwiftDeviceCalendarPlugin.swift` outright (845 lines) and
      replaces it with a full Objective-C implementation
      (`DeviceCalendarPlugin.m`/`.h` + Obj-C model classes). Exactly the
      opposite direction from where this fork has gone (iOS 17
      write-only permissions, the #605 EKEventStore fix, #569's
      cleanup — all Swift, all built on the current file). Also ships a
      binary `.DS_Store` in the diff, a sign of an unreviewed/low-effort
      PR. Nothing to extract.

### 3. Tests

- [ ] Add/update tests for everything merged so far. This repo's test
      layout: Dart unit tests live under each package's own `test/`
      dir; there's also `example/integration_test/` for real
      device/platform-channel-level coverage (per patterns seen in
      sibling plugin `device_calendar_plus`'s CONTRIBUTING.md — check
      whether `device_calendar` itself already has an equivalent
      `integration_test` setup, since it predates the federated-plugin
      convention that repo uses).
- [x] Regression test for the new `CalendarAccessLevel.writeOnly`
      request path, at the Dart/method-channel boundary: added
      `RequestPermissions_Defaults_ToFullAccessLevel` and
      `RequestPermissions_WriteOnly_PassesAccessLevelArgument` to
      `test/device_calendar_test.dart`, asserting `requestPermissions()`
      sends `calendarAccessLevel: 'FULL'` by default and `'WRITE_ONLY'`
      when requested. All 15 tests in the file pass (`flutter test`),
      `flutter analyze` clean (only pre-existing unrelated warnings).
- [ ] The #605 EKEventStore recreate-after-grant fix and the
      `hasEventPermissions(requireFullAccess:)` gating logic live
      entirely in `SwiftDeviceCalendarPlugin.swift` and aren't
      observable through the method channel (the store recreation is
      an internal implementation detail, not a return value) — **not
      testable from Dart**. Needs an Xcode-side unit/integration test
      (`example/integration_test/` or an `XCTest` target), which
      requires a Swift/Xcode toolchain not available in this
      environment. Left for whoever picks this up on a Mac.

### 4. Prep for publishing

- [ ] Decide package name. Likely **cannot publish as `device_calendar`**
      — that name is already taken by the upstream package on pub.dev,
      and pub.dev does not allow name squatting/collision with an
      existing published package regardless of fork relationship.
      Needs a distinct name (e.g. something signaling "community fork" /
      "maintained fork of device_calendar"). Get bencouture's input on
      naming before proceeding — this is a real decision, not a
      mechanical one.
- [ ] Update `pubspec.yaml`: name, description, version (start at
      something like `1.0.0` or continue from `4.3.1` upstream left off
      at — decide sequencing), `repository`/`homepage` pointing at the
      fork.
- [ ] Update `CHANGELOG.md` with everything done in this revival pass.
- [ ] Update `README.md` further if needed (already has the new
      write-only permission docs from this pass) — add a note near the
      top explaining this is a maintained fork, why it exists, and its
      relationship to upstream.
- [ ] Run `dart pub publish --dry-run` (safe, no side effects) to catch
      any packaging issues before the real publish.

### 5. Publish

- [ ] **Stop and confirm with bencouture immediately before this step**,
      per ground rule #7 above, regardless of how "ready" everything
      else looks.
- [ ] `dart pub publish` under bencouture's pub.dev account/credentials.

### 6. Wire up Vikunja

- [ ] In `/home/ben/git/app` (the Vikunja Flutter app), update
      `pubspec.yaml` to depend on the newly-published package instead
      of `device_calendar_plus`.
- [ ] Update `lib/presentation/manager/calendar_sync.dart` and
      `lib/presentation/pages/settings_page.dart` (the calendar-sync
      settings UI) to match the new package's API — note the API shape
      differs from `device_calendar_plus` (different method names/
      signatures; this package uses `Event`/`Calendar` models and
      `Result<T>` wrapper types, not `device_calendar_plus`'s API).
      Re-read both files fresh before editing — don't assume the old
      `device_calendar_plus`-based implementation maps 1:1.
- [ ] Re-run the full existing calendar-sync test suite
      (`test/presentation/calendar_sync_test.dart`,
      `test/presentation/manager/task_page_controller_test.dart`) and
      fix/rewrite the fakes to match the new package's interfaces.
- [ ] Rebuild the debug APK and manually re-verify on the physical
      device (the whole point of this fork was fixing a real,
      user-visible bug: completed tasks' calendar events not actually
      being deleted from Google Calendar). Confirm that specific
      scenario now works end-to-end with the new package.
