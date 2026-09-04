# FitApp — Native iOS (Swift/SwiftUI) rewrite

Full native replacement for the Expo/React Native app (`../app`, `../components`, etc.),
targeting iOS only. Backend is **CloudKit** (Apple's own, private database, scoped
to the signed-in iCloud account) — this is a deliberate break from the RN app's
Firebase backend, so existing Firebase user data does **not** carry over automatically.

## Status (this pass)

**Done**
- Project scaffold (XcodeGen `project.yml`) with an iCloud/CloudKit entitlement,
  no third-party SPM dependencies needed (CloudKit ships with iOS).
- Data layer: `UserProfile`, `Exercise`, `DailyPlanDoc`/`PlannedExercise`,
  `AchievementDefinition` models, each with `CKRecord` mapping helpers.
- Exercise catalog (160 exercises) and achievement catalog (17 definitions) extracted
  from the RN `.ts` data files and bundled as `Resources/Data/{exercises,achievements}.json`
  (these are static, bundled with the app — no backend involved).
- i18n: all 234 `en`/`tr` keys from `i18n/en.ts` / `i18n/tr.ts` converted to
  `Localizable.strings`, language auto-detected from device locale (`LocalizationManager`).
- Account/session: `CloudKitAccountService` checks `CKContainer.accountStatus()` —
  no login screen needed; the app just uses whichever iCloud account is signed in
  on the device. `LoginView` only shows up if iCloud isn't available (prompts the
  user to sign in via Settings).
- Screens: Home (today's workout summary), Exercises (browse/search/detail),
  Weekly Plan (simplified single-day editor), Profile (stats + achievements
  progress + rename).
- **Rest timer** (new, not in the RN app): `RestTimerView`/`RestTimerService` —
  1 dk / 3 dk presets or a custom duration (15s steps), countdown ring, and a
  soft two-tone beep (`Resources/Sounds/rest_timer_beep.wav`) when it ends.
  Reachable from Home's quick actions and from each exercise's detail screen.
  Works in two layers so it's audible whether the app is foregrounded or the
  phone is locked: `AVAudioPlayer` plays the cue directly while the app is
  active (audible even with the silent switch on), and a local notification
  scheduled at start time carries the same sound for when the app is
  backgrounded/locked (this path **does** respect the silent switch/Focus,
  same as any normal notification — there's no way around that without
  Apple's Critical Alerts entitlement). First use prompts for notification
  permission.
- **Muscle map** (new, not in the RN app): `MuscleMapView`/`MuscleMapService`
  + `BodyDiagramView` — a simple geometric front/back body diagram (circles/
  capsules/rounded rects, deliberately not a human figure) showing which
  muscle groups were trained "Bugün" vs. "Bu Hafta", colored by exercise
  count, gray if untouched. Reachable from Home's quick actions.
  `PrimaryMuscleResolver` (Exercise.swift) ports the RN app's
  `derivePrimaryMuscle`/`MUSCLE_TO_PRIMARY`/`PRIMARY_OVERRIDE` tables
  verbatim from `utils/exercisesData.ts` — the raw `muscles[0]` strings in
  the exercise data ("Quads", "Lats", "Rear Delts", ...) don't match
  `PrimaryMuscle`'s cases directly, so this mapping matters; an earlier,
  naive version of this file mis-bucketed most exercises into "Core" before
  the table was ported. Weekly aggregation fetches the week's 7 `DailyPlan`
  records by known recordID (`CKDatabase.records(for:)`, no query index
  needed) and merges their items.
- **App icon** (placeholder): `Resources/Assets.xcassets/AppIcon.appiconset` —
  a plain 1024×1024 flat-color barbell glyph (brand purple `#5A62F2` + white),
  generated programmatically since there was no real app icon at all before
  (App Store Connect validation rejects builds with a missing icon, so this
  was a real blocker for TestFlight, not just cosmetic). Swap
  `icon-1024.png` for a real design whenever one exists — no other project
  changes needed, Xcode regenerates every smaller size from that one image.
- **Warning: the checked-in `FitApp.xcodeproj` was hand-authored** (see Setup
  below) and hasn't been opened in real Xcode yet — flag anything that
  doesn't parse and it'll get patched.

**Before you can actually submit to TestFlight** (none of this is something
I can do from here — all Apple-account-side steps):
1. An active **Apple Developer Program** membership (paid) on the account
   you'll sign in with in Xcode — TestFlight/Archive distribution doesn't
   work on a free account.
2. **CloudKit schema → Production.** The container (`iCloud.com.fitapp.workout`)
   auto-creates its `UserProfile`/`DailyPlan` record types in the
   *Development* CloudKit environment the first time the app saves a record
   from a debug build. A TestFlight build is *release*-signed, which makes
   CloudKit talk to the *Production* environment instead — and that's empty
   until you explicitly promote it. So: run the app once from Xcode on your
   own device/simulator (creates a profile → creates the schema in Dev),
   then go to the [CloudKit Dashboard](https://icloud.developer.apple.com) →
   your container → **Deploy Schema to Production**. Skip this and every
   CloudKit read/write in the TestFlight build will silently fail.
3. In App Store Connect, an app record for bundle ID `com.fitapp.workout`
   (reuse the existing one if the RN app was already there — same bundle ID).
4. Xcode → Signing & Capabilities → set your Team (Automatic signing handles
   the rest, including the iCloud container, once a paid-account Team is set).
5. Product → Archive → Distribute App → TestFlight & App Store.

**Not ported yet** (tracked as follow-up work)
- Multi-plan Weekly Plan editor (`app/(tabs)/weekly-plan.tsx` is 46KB — drag reorder,
  named/multiple plans, AI import, rename/duplicate). This pass ships a single-day
  add/remove/complete loop against one `DailyPlan` CKRecord per date.
- Full Today/Workout session screen (exercise-by-exercise flow, set logging),
  rest-day suggestions, AI suggestion modal — the rest timer above covers only
  the "wait between sets" piece of this.
- Full Achievements/Analytics screens (analytics charts, history week strip).
- Health onboarding (BMR/TDEE calculator), Subscription/Paywall, profile photo
  (CloudKit supports this via `CKAsset` — not wired up yet).
- Achievement unlock **writes** back to CloudKit (current `AchievementService` only
  *reads* stats to compute progress client-side).
- **Firebase → CloudKit data migration.** If the RN app has real production users,
  their Firestore data needs an explicit one-time export/import step into CloudKit;
  nothing here does that automatically (different backends, different user identity
  model — Firebase uid vs. iCloud account).

Pick these up by adding one Swift file per screen under `FitApp/Views/Main/`, following the
pattern in `HomeView.swift`/`WeeklyPlanView.swift` (an `ObservableObject` service + a
SwiftUI view, both cross-referencing the matching RN file in a comment).

## Setup (do this on your Mac)

There are two ways to get `FitApp.xcodeproj`. Use whichever fits — **no
Homebrew/terminal installs are required for option A**, only Xcode itself.

### Option A — open the checked-in project directly (no terminal tools needed)
A ready-made `FitApp.xcodeproj` is committed at `ios-native/FitApp.xcodeproj`
(hand-authored, not machine-generated by XcodeGen — see the note below).
1. Double-click `FitApp.xcodeproj` (or `open ios-native/FitApp.xcodeproj`) to open it in Xcode.
2. Target FitApp → Signing & Capabilities: set your Team. Confirm the iCloud
   capability shows CloudKit checked and container `iCloud.com.fitapp.workout`
   selected (it's pre-wired via `FitApp/Resources/FitApp.entitlements`); if Xcode
   flags the container as missing, click the refresh/"+" to let it create that
   container under your Apple Developer account.
3. Build & run (⌘R) on a **real device or simulator signed into a real iCloud
   account** (Settings app → your name at the top) — CloudKit's private database
   won't work without one.
4. No server-side schema setup needed up front — record types (`UserProfile`,
   `DailyPlan`) and fields are inferred automatically on first save; inspect them
   afterward at https://icloud.developer.apple.com (CloudKit Dashboard).

> This `.xcodeproj` was assembled by hand (matching every file under `FitApp/`)
> rather than run through Xcode/XcodeGen, since it was built in an environment
> without either. It **hasn't been opened/compiled in real Xcode yet** — if
> something doesn't parse right when you first open it, the fallback is Option B,
> or let me know what error Xcode shows and I'll patch the `.pbxproj`.

### Option B — regenerate via XcodeGen (if you do have Homebrew/terminal access)
1. `brew install xcodegen`
2. From this folder: `xcodegen generate` — regenerates `FitApp.xcodeproj` from
   `project.yml` (useful after adding/removing files, since Option A's project
   won't auto-pick-up new files the way XcodeGen's `sources:` glob does).
3. `open FitApp.xcodeproj` and continue from step 2 in Option A.

### Why no login screen?
CloudKit's private database is already scoped to whichever iCloud account is signed
in on the device — there's no separate username/password/email-link step the way
Firebase needed one. `LoginView` only appears if `CKContainer.accountStatus()` comes
back `.noAccount`/`.restricted`, and just points the user at Settings.

## Re-syncing data from the RN app later
The exercise/achievement JSON was generated by running the RN `.ts` files through
`esbuild-register` in Node and dumping the exported arrays as JSON (they're plain
data files, no React/Firebase imports, so this works without a device). If those
`.ts` files change again, regenerate with the same approach and drop the new JSON
into `FitApp/Resources/Data/`. This part is backend-agnostic (still applies whether
the app talks to Firebase or CloudKit).
