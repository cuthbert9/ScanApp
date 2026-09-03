# scanapp — architecture

Orientation for anyone new to the codebase, human or AI. Working rules live in
[CLAUDE.md](CLAUDE.md); this file describes what exists and where.

## What this app is

A Flutter app for **Zebra MC9450 rugged handhelds** — warehouse dispatch and
truck loading. The device shapes almost every decision: a ~320×533 dp canvas,
gloved operation, a hardware scan trigger and physical keypad, use in bright
sun and dim aisles, and hundreds of scans a shift. `CLAUDE.md` has the full
constraint list and the per-change checklist.

Barcode capture will arrive as **Zebra DataWedge intent broadcasts**, not a
camera preview. That integration is **not built yet**.

## Running it

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # required
flutter run
```

Generated files (`*.g.dart`, `*.freezed.dart`) are **git-ignored**, so a fresh
clone will not compile until codegen has run. Re-run it after touching any
`@freezed`, `@riverpod` or `@JsonSerializable` file.

```bash
dart format . && flutter analyze
flutter test
```

## Directory map

```
lib/
  main.dart                     ProviderScope + runApp. Nothing else.
  app/                          Composition root. Wiring only, no behaviour.
    app.dart                    MaterialApp.router, theme mode, text scale.
    router/routes.dart          Every path as a constant.
    router/app_router.dart      GoRouter, the auth guard, the tab branches.

  core/                         Depends on nothing in the app.
    design/                     The design system. See below.
    errors/app_exception.dart   Sealed failure vocabulary.
    result/result.dart          Sealed Result<T> = Success | Failure.
    sync/                       The device's outbox. Infrastructure, not a
                                feature — see "The outbox" below.

  shared/widgets/               Reusable, feature-agnostic widgets.
    display/                    AppBadge, AppCountBadge, AppDetailRow,
                                AppMetaRow, AppSectionHeading, AppStatRing,
                                AppStatTile
    feedback/                   AppInfoPanel, PlaceholderScreen
    layout/                     AppScreenHeader, AppSummaryStrip,
                                AppBottomActionBar
    widgets.dart                Barrel — import this, not individual files.

  features/
    auth/                       Sign-in. Stubbed.
    orders/                     The loading queue (home tab).
    loading/                    The load session: scan, verify, reconcile.
    sync/                       Presentation for the outbox in core/sync/.
    settings/                   Operator, shift figures, station, preferences.
    shell/                      Bottom-tab chrome around the branches.
```

Five widgets moved into `shared/` as second and third consumers appeared —
`AppScreenHeader` and `AppSectionHeading` from `orders`, `AppBottomActionBar`
from a private class on the queue screen, `AppSummaryStrip` once orders, scan
and load all needed the same navy panel, and `AppDetailRow` once the sync
screen's local-queue card needed the reconciliation card's label/value line.
That is rule 2's "used by two or more features" bar being applied rather than
near-duplicates accumulating.

## The outbox

`lib/core/sync/` holds the device's outbox — mode, queued records, flush — with
its own domain, data and application layers. It is the only part of `core/` that
carries app domain rather than pure infrastructure, and that is deliberate.

Three unrelated places read it: the shell's tab badge, the scan header's
indicator, and the sync screen. If a feature owned it, the shell would have to
import that feature, which rule 3 forbids. Giving each consumer its own copy was
the alternative and was rejected for the same reason it was on the Load tab: a
flush would empty one and leave the others stale.

So the queue is infrastructure — every feature's writes eventually land in it,
and it depends on nothing above it — and `features/sync/` is presentation only.

`pendingSyncCountProvider` is derived from the queue, so flushing empties the
badge without anything having to remember to update it.

## The dependency rule

```
features/  →  shared/  →  core/
```

One direction only. `core/` knows nothing above it; `shared/` may use `core/`
but no feature; **a feature never imports another feature**. If two need the
same thing, it moves down into `shared/` or `core/`.

Inside a feature:

| Folder | Holds | May not |
|---|---|---|
| `domain/` | Models, repository *interfaces*. Pure Dart. | Import Flutter |
| `data/` | Repository *implementations*, DTOs, sources | Leak transport errors |
| `application/` | Riverpod controllers | Contain widgets |
| `presentation/` | Screens and feature-only widgets | Contain business logic |

`presentation/` never reaches into `data/`. It goes through `application/`,
which depends on the `domain/` interface. That indirection is what makes the
backend swap a one-line change.

## Design system

Three layers, in `lib/core/design/`. Code reads **downward only**.

| Layer | Location | What |
|---|---|---|
| 1 Primitives | `tokens/primitive_tokens.dart` | Raw ramps and scales. The only literals in the app. |
| 2 Semantic | `extensions/` | 58 colour roles + spacing, radii, sizes, type, motion, as `ThemeExtension`s. |
| 3 Component | `theme/app_theme.dart` | `ThemeData`, so unstyled Material widgets already look right. |

Screens read **Layer 2 only**, through `BuildContext`:

```dart
context.colors.surface   context.spacing.md    context.radii.cardBorder
context.type.bodyMd      context.sizes.iconMd  context.motion.feedback
```

Layer 1 is deliberately **not** exported from `design.dart`. A hook
(`.claude/hooks/design-token-guard.py`) rejects literals and call-site styling
in `lib/features/**` and `lib/shared/**`. Adding or changing a token is the
`/design-token` skill.

The palette is navy (chrome, primary action), gold (in-progress), teal (cold
chain), tan (blocked, sync backlog) on cool grey.

## Navigation

```
/login                          outside the shell — no tabs
   │  guard: signed out → /login ; signed in at /login → /orders
StatefulShellRoute.indexedStack (AppShell: the bottom tab bar)
   ├── /orders    LoadingQueueScreen   ← home
   ├── /scan      ScanScreen                ┐ both served by
   ├── /load      LoadReconciliationScreen  ┘ features/loading/
   ├── /sync      SyncScreen
   └── /settings  SettingsScreen
```

`indexedStack` gives each tab its own navigator, so switching away and back
preserves scroll position — losing your place in a long queue mid-shift is a
real cost on this device.

Every tab now has a real screen. `PlaceholderScreen` is still in `shared/` for
the next unbuilt one, but nothing routes to it.

## Feature inventory

| Feature | Owns | Entry | State |
|---|---|---|---|
| `orders` | The dock's loading queue: staged orders, counts, selection | `LoadingQueueScreen` | Complete UI, fake data |
| `loading` | The load session — scanning units onto a truck, judging them against the manifest, and reconciling before seal | `ScanScreen`, `LoadReconciliationScreen` | Complete UI, fake data |
| `sync` | Presentation for the outbox — mode selection and flushing. The queue itself lives in `core/sync/` | `SyncScreen` | Complete UI, fake store |
| `settings` | The operator, shift figures, the station, and the three preferences that apply | `SettingsScreen` | Complete UI, fake data |
| `auth` | Sign-in and the session flag | `LoginScreen` | Stub — accepts anything |
| `shell` | Bottom-tab chrome | `AppShell` | Complete |

## One feature, two tabs

`features/loading/` serves both the SCAN and LOAD tabs, because they are two
views of one aggregate: a delivery order going onto a truck. Scan captures it,
Load reconciles it.

Splitting them into separate features and then sharing the session between them
would have meant a feature-to-feature import, which rule 3 forbids. Giving each
its own repository was the alternative, and was rejected: with separate fakes,
scanning a unit on SCAN would leave LOAD showing stale figures. Reading the same
session means the 14th scan moves every number on the reconciliation screen at
once — there is one copy of the truth.

`LoadReconciliation.from(session)` is a **pure read model**. Ordered, verified,
short, over, first-pass yield, weight and volume are all computed; nothing is
stored, so nothing can drift.

`ScanIssue` exists so reconciliation can count over-scans separately from short
lines without matching on English prose — a message reword would otherwise break
the arithmetic.

## Scanning

`ScanSessionController.submitScan(String raw)` is the **single entry point** for
scanned input. The on-screen field calls it today; when the DataWedge intent
bridge lands, its stream calls the same method and nothing downstream changes.

The field is not only a development stand-in. DataWedge's **keyboard-wedge**
mode types the decoded barcode into the focused field and sends Enter, so on a
real MC9450 this receives genuine hardware scans with no native code. It stays
useful afterwards too, because warehouse labels get torn and someone has to key
the number in. The field re-takes focus after every submission so a rapid
sequence of trigger pulls never lands nowhere.

`Gs1Barcode.parse` decodes both the bracketed form `(00)…(10)…(17)…` and raw
concatenated scanner output, using FNC1 separators for variable-length AIs. It
never throws: an undecodable code still produces a feed row, because a scanner
that appears to do nothing is worse than one that reports a problem.

Manifest rules are applied most-specific-first in `_judge` — unknown, then
duplicate, then over-count — so "you already scanned this" beats "the load is
full".

## Data and errors

Repositories return `Result<T>`, never throw. Data sources translate every
transport error into a sealed `AppException` at the repository edge, so UI never
sees a `DioException` or a `PlatformException`. Both types are `sealed`, so the
analyzer catches an unhandled case.

`LoadingQueueController` unwraps the `Result` and rethrows the exception, which
Riverpod turns into `AsyncError`. Widgets therefore deal only in `AsyncValue`
and render `AppException.message` — written for an operator — never the raw
error.

### Swapping in the real backend

The backend is a separate MSSQL-backed service; this app only calls its
endpoints. Until it exists, features run on fakes.

`FakeLoadingQueueRepository` serves the queue and can be told to fail, so the
error state is built and looked at rather than assumed.

One provider decides which implementation is live:

```dart
// lib/features/orders/application/loading_queue_controller.dart
@riverpod
LoadingQueueRepository loadingQueueRepository(Ref ref) {
  return const FakeLoadingQueueRepository();
}
```

Return the HTTP implementation there and nothing else changes. Tests override
the same provider.

## Testing

Six test files, 70 tests:

| File | Covers |
|---|---|
| `gs1_barcode_test.dart` | The parser, directly — bracketed, concatenated, FNC1, bare EANs, expiry edge cases, malformed input, identity. Pure Dart, no widget binding. |
| `loading_queue_responsive_test.dart` | The home screen: derived counts, the no-tap CTA, and overflow at four canvases. |
| `scan_screen_test.dart` | The manifest rules end to end (accept, duplicate, over-count, unknown, empty) plus overflow at six canvases. |
| `load_reconciliation_test.dart` | Every derived figure, the amended-manifest notice, overflow at four canvases, and that a scan on the session moves the load figures — the test that justifies scan and load being one feature. |
| `sync_screen_test.dart` | Derived queue figures, mode selection changing the state word, and that flushing empties both the queue and `pendingSyncCountProvider` — the badge the shell renders. |
| `settings_screen_test.dart` | Derived shift figures and initials, the station card, chart tap-to-inspect, that theme and text-size preferences actually apply, and that signing out with a non-empty outbox warns first. |

Screens are rendered at every canvas the device can present — portrait 320×533,
landscape 533×320, keyboard up, font scale 1.3, and the combinations — asserting
`tester.takeException()` is null. Flutter reports a `RenderFlex overflowed` as a
thrown error, so layout regressions fail the build instead of shipping.

This caught two real bugs during the scan build: the cold-chain readings
overflowed at font scale 1.3, and landscape-with-keyboard leaves about 140 dp,
less than the pinned chrome needed.

Two test-authoring traps worth remembering. Inside `testWidgets` the clock is
faked, so awaiting a repository future *before* any `pump()` never completes —
pump first, then drive the notifier. And a lazy `ListView` has not built what is
below the fold, so asserting a notice is absent proves nothing until you have
scrolled to where it would be.

## Decisions

| Decision | Why |
|---|---|
| **Riverpod 3 + codegen** | Compile-safe DI, least boilerplate, and provider override is the backend swap seam. |
| **Generated files git-ignored** | `*.freezed.dart` / `*.g.dart` are build output; committing them causes constant merge conflicts. Cost: codegen before first run. |
| **No `riverpod_lint` / `custom_lint`** | They lag Riverpod 3.4 and would force Freezed back to 2.x. The hooks in `.claude/hooks/` cover that ground. |
| **DataWedge natively, not `flutter_datawedge`** | The package is well behind current Flutter. DataWedge is only intent broadcasts, so a small Kotlin BroadcastReceiver behind a `ScannerService` interface avoids the dependency risk. Not built yet. |
| **UI before backend** | The endpoints do not exist. Fakes behind a repository interface keep the UI honest and the seam real. |
| **Design tokens over ad-hoc styling** | Dozens of screens on a device that may need a high-contrast sunlight mode. Tokens make that a two-file change. |
| **`PlaceholderScreen` over four stub features** | A folder holding one stub is noise. Structure follows real code. |

## Shedding chrome as space runs out

The scan screen keeps focus in its input, so the keyboard is up almost all the
time and the viewport is far smaller than the device's nominal 533 dp. It sheds
optional chrome in two stages rather than forking the layout:

| Condition | Dropped |
|---|---|
| `tight` — keyboard up, or short viewport | Summary strip collapses to one line; cold-chain banner hidden. ~110 dp back. |
| `minimal` — `context.isSeverelyConstrainedHeight`, under 260 dp | Header, strip and action bar hidden; input label dropped. Leaves the input and the feed, which is what an operator uses mid-scan. |

Everything returns when the keyboard closes. Both flags come from
`context` helpers in the design layer, so the size comparisons live in one
place.

## Charts

`WeeklyScanChart` is the only data visualisation, and it follows the project's
dataviz rules rather than taste:

- **One series**, so no legend — the title names it. Today is an emphasised mark
  *within* the series, not a second series.
- **Colours were validated, not picked.** `chartBar` and `chartBarEmphasis` were
  run through the palette checker as a one-hue ordinal ramp against each theme's
  card surface. The design's paler tan failed at **1.38:1 contrast** and low
  enough chroma to "read gray" — on a device used in direct sunlight that is a
  legibility problem, not a nitpick. The passing steps are `#C8A227`/`#876A16`
  on light and `#A8861C`/`#DCBB5C` on dark.
- The dark steps are **chosen, not flipped**: on a dark card the *lighter* step
  is the prominent one.
- The checker's sub-3:1 warning obligates relief, so every value is reachable as
  text — a caption line, a per-bar semantic label, and tap-to-inspect.
- **Tap replaces hover**, which does not exist on a gloved handheld.

Re-run the checker before changing any chart colour; do not eyeball it.

## Not built yet

- **DataWedge intent bridge.** No `ScannerService`, no native BroadcastReceiver,
  no hardware-trigger handling. Note that keyboard-wedge mode already works
  through the scan field, so the device is usable before this lands.
  **Keypad focus order is still unwired** — every action is reachable by touch,
  and the scan flow works from the keypad, but tab order elsewhere is not set.
- **Scans do not write into the outbox.** The sync queue is seeded
  independently, so its pending count is not literally two of the session's
  scans. Wiring capture → outbox is the offline-queue feature proper.
- **Nothing is encrypted.** `AES-256 at rest` is a label on the sync screen
  describing intended behaviour; the fake store holds records in memory in the
  clear. Do not read that line as a statement about the current build.
- **Nothing persists.** Sync mode, the queue, the load session, and the theme
  and text-size preferences all reset on restart — there is no local store yet.
- **No dispatch map.** The station card carries the base details on their own.
  It is the seam a real map drops into; a decorative stand-in was deliberately
  left out so nothing on screen implies a live map that is not there.
- **`Change station` has no destination**, and the scanner and session cards are
  display-only — language, idle lock and shift auto-close are shown but wired to
  nothing.
- **Real auth**, real API client, offline queue and sync. The Sync badge count
  is a constant.
- `Open <DO>`, `Manifest` and `Reconcile` have no destinations yet.
- **`Seal load` is a no-op.** It amends the manifest and reduces the delivery
  note from 14 lines to 13, so the real action needs a confirmation step before
  it is wired — the warning notice is not a substitute for one.
- Vehicle capacities are fixed constants; there is no fleet lookup.
- The cold-chain temperature and door-open readings are fake.
