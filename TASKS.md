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

- [ ] **#590** "Upgrade to timezone 0.10.0" — claimed superseded by
      #604 (which went further, to 0.11.0). Verify: does #590 touch
      anything #604 didn't (check `git diff $(git merge-base develop
      pr-590) pr-590` after fetching `pull/590/head`)? If genuinely
      subsumed, note it closed here; if not, review it properly.
- [ ] **#580** "fix event url" — claimed superseded by #594 (itself
      folded into #604). Same treatment: fetch, diff against true
      merge-base, confirm it's actually the same change before
      considering it closed.

### 2. Remaining PRs needing a full individual review (13, not merged/decided yet)

Use the same review method as the completed ones above: fetch via
`git fetch upstream pull/<N>/head:pr-<N>`, diff against
`git merge-base develop pr-<N>`, read it fully, verify (pub get /
analyze for Dart changes; careful manual reasoning for native code),
then either merge with attribution, extract-and-merge the valid parts,
or skip with a clearly written reason — same as every item in the
"done" section above models.

Ordered newest-first (most likely to still be relevant first):

- [ ] **#569** "Remove native ios event modal tool bar" (2024-11-13) —
      flagged in original triage as a real *behavior* change (removes
      UI), not obviously a bug fix. Read the linked issue/rationale
      carefully before deciding; this one needs a judgment call on
      whether it's a fix or a breaking UX change that shouldn't be
      default.
- [ ] **#531** "Fix: Update Set\<T\> to List\<T\> in calendar_event.dart
      to comply with rrule 0.2.16" (2024-03-17) — check current `rrule`
      version already in use (this repo may have already moved past
      0.2.16 via other commits; verify relevance first).
- [ ] **#512** "namespace change" (2023-10-27) — likely superseded by
      #612 (AGP9) and the #587-extraction (namespace/manifest cleanup),
      both already merged. Verify-then-close is plausible outcome here
      too, same as #590/#580.
- [ ] **#510** "rel" (2023-10-14, base: `master` not `develop`) —
      cryptic title, wrong base branch for this workflow. Investigate
      what it actually contains before doing anything with it.
- [ ] **#502** "test update" (2023-09-16) — vague title, read the actual
      diff to know what it does before judging.
- [ ] **#471** "macOS support" (2023-02-09) — a whole new platform
      target, meaningfully larger in scope than anything reviewed so
      far. Treat as its own mini-project if pursued; confirm with
      bencouture whether macOS support is even wanted before investing
      review time here.
- [ ] **#454** "Removed platform-specific logic from the example app."
      (2022-11-02) — example-app-only, low risk, but old; check it still
      applies cleanly.
- [ ] **#448** "[5.0] rrule legacy layer" (2022-10-12, base: `develop`)
      and **#445** "5.0 prerelease" (2022-10-07, base: `release`) — look
      like two pieces of the same abandoned major-version-bump attempt.
      Review together, not separately. Likely candidates for "skip,
      abandoned effort" but confirm by reading both before deciding.
- [ ] **#435** "Adding new features" (2022-08-25, base: `master`) — vague
      title, wrong base branch. Investigate contents before judging.
- [ ] **#428** "Android recurring events, edit single instance"
      (2022-06-10) — a real feature, not just a fix; check for overlap
      with any recurring-event handling already in `develop` before
      merging.
- [ ] **#419** "update mac support" (2022-04-16) — likely an earlier,
      probably-superseded piece of whatever #471 is; review both
      together.
- [ ] **#213** "change ios part - migration to Objective-c"
      (2020-03-31) — current iOS implementation is already Swift
      (`SwiftDeviceCalendarPlugin.swift`); this PR appears to move the
      *opposite* direction and is almost certainly obsolete. Very likely
      "skip" but confirm by at least reading the diff before writing
      that down as final.

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
