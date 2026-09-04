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

  domain/                       NEW — the shared aggregate and the contracts.
    models/                     Order (+ lines), Officer, Station, Vehicle,
                                ScanEvent, LoadSeal, SyncRecord/Status,
                                ColdChainLog, ShiftStats. Pure Dart.
    repositories/               The seven interfaces. See README swap points.

  data/                         NEW — one in-memory store behind all seven.
    mock_seed.dart              EVERY seed value. Edit this to change scenarios.
    mock_backend.dart           The single source of truth + all the rules.
    mock_*_repository.dart      Thin adapters: latency in, Result out.

  shared/widgets/               Reusable, feature-agnostic widgets.
    display/                    AppBadge, AppCountBadge, AppDetailRow,
                                AppMetaRow, AppSectionHeading, AppStatRing,
                                AppStatTile, AppSummaryCompactLine
    feedback/                   AppInfoPanel, PlaceholderScreen
    layout/                     AppScreenHeader, AppSummaryStrip,
                                AppBottomActionBar, AppPinnedSummary
    widgets.dart                Barrel — import this, not individual files.

  app/state/                    App-level stores every screen watches.
    dock_controller.dart        Staged orders, the open order, hasViewedLoad.
    sync_controller.dart        The outbox + pendingSyncCount.
    preferences_controller.dart Theme and text size.

  features/                     **Presentation and per-screen controllers only.**
    auth/                       Sign-in. Stubbed.
    orders/                     The loading queue (home tab).
    loading/                    Scan & Verify and Load Reconciliation.
    sync/                       Offline Sync.
    settings/                   Operator, shift figures, station, preferences.
    shell/                      Bottom-tab chrome around the branches.
```

Features no longer carry `domain/` or `data/` folders. The aggregate is shared,
so it lives below them — which is what rule 3 said should happen the moment two
features needed the same thing.

Five widgets moved into `shared/` as second and third consumers appeared —
`AppScreenHeader` and `AppSectionHeading` from `orders`, `AppBottomActionBar`
from a private class on the queue screen, `AppSummaryStrip` once orders, scan
and load all needed the same navy panel, and `AppDetailRow` once the sync
screen's local-queue card needed the reconciliation card's label/value line.
That is rule 2's "used by two or more features" bar being applied rather than
near-duplicates accumulating.

## One aggregate, one store

`lib/domain/` holds the models and the seven repository interfaces.
`lib/data/` holds `MockBackend` — the single in-memory store — and one `Mock*`
adapter per interface. Screens talk to interfaces, never to a concrete class.

**`Order` carries `lines[]`, and every figure is derived from them.** Units,
verified, held, short, first-pass yield, weight and volume are all getters on
the aggregate, so changing one line's `state` moves every number on every
screen at once. Nothing downstream recomputes or caches them.

`DockController` in `app/state/` is the app-level store: it holds the staged
orders, the open order and the `hasViewedLoad` flag. Every mutation goes
through a repository and then `refresh()`, which is why the queue card behind
the Scan screen is already correct when you go back to it.

This replaced four parallel models of the same order — `LoadingOrder` with a
scalar `units`, plus `ScanSession`, `LoadReconciliation` and `SyncQueue` — which
could not agree with each other by construction.

## The outbox

The outbox lives behind `SyncRepository` and is held by `SyncController` in
`app/state/`. Three unrelated places read it: the shell's tab badge, the amber
dot on every screen header, and the Sync screen.

`pendingSyncCountProvider` is derived from the queue, so a flush empties all
three at once and none can go stale. Every scan and every seal enqueues a
record, which is why the badge moves when you scan.

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
| `orders` | The dock's loading queue: staged orders, counts, selection | `LoadingQueueScreen` | Wired to the mock backend |
| `loading` | Scanning units onto a truck, judging them against the manifest, and reconciling before seal | `ScanScreen`, `LoadReconciliationScreen` | Wired, incl. sealing |
| `sync` | Presentation for the outbox — mode selection and flushing | `SyncScreen` | Wired, incl. flush |
| `settings` | The operator, shift figures, the station, and the preferences that apply | `SettingsScreen` | Wired, incl. station picker |
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

43 tests, four files:

| File | Covers |
|---|---|
| `mock_backend_test.dart` | The rules, directly — the scan ladder in order, FEFO, sealing amended, a sealed order refusing scans, flushing, air-gapped refusal, simulated offline, station re-sync. No widgets. |
| `gs1_barcode_test.dart` | The GS1 parser — bracketed, concatenated, FNC1, bare EANs, expiry edge cases, malformed input. |
| `demo_path_test.dart` | The whole flow through the real router and shell: open an order, debug-scan, reconcile, seal, watch it leave the queue, flush the badge, switch theme. |
| `screens_responsive_test.dart` | All five tabs at portrait, landscape, and both at font scale 1.3, asserting no `RenderFlex overflowed`. |

Rules are tested at the backend rather than through widgets, which is the whole
point of keeping them there. The demo path is the integration test; the
responsive sweep is the layout safety net.

Three test-authoring traps worth remembering. Inside `testWidgets` the clock is
faked, so awaiting a repository future before any `pump()` never completes.
The shell's `IndexedStack` keeps every screen mounted, so a bare
`find.byType(CustomScrollView)` (or `ListView`) matches several — scope
finders to the screen you mean. And since every screen is now one scrolling
sliver list, a widget placed near the bottom — the bottom action bar most of
all — is not built until scrolled near the viewport; `find` on it returns
nothing until then, not a "not visible yet" hint.

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

## Screen chrome: scrolling header, pinned dashboard

All five tabs share the same shape now: the whole screen is one
`CustomScrollView`, not a `Column` of fixed chrome around a scrolling body.

- `AppScreenHeader` is a plain scrolling sliver — it moves with the page,
  buying back the vertical room it used to hold permanently.
- The small stats dashboard beneath it (`AppSummaryStrip`,
  `QueueSummaryStrip`, `ScanProgressStrip`) is wrapped in `AppPinnedSummary`
  (`shared/widgets/layout/`), which sticks it to the top once scrolled there
  and shrinks it to a one-line `AppSummaryCompactLine`
  (`shared/widgets/display/`) — the same figures read left to right instead
  of stacked, not a different state.
- `AppBottomActionBar` is the last sliver in the list rather than
  `Scaffold.bottomNavigationBar` — it scrolls with the content instead of
  staying pinned above the tab bar. Orders' "Open" bar is the one exception:
  it stays pinned, since it is the single next action and only appears once
  something is selected.

Three things worth knowing before touching this:

- **A `SliverPersistentHeader` needs a concrete pixel extent** — the one
  place a box holding text has a fixed height, which rule 1c otherwise
  forbids. `AppSizes.summaryStripExpandedHeight` /
  `summaryStripCollapsedHeight` carry headroom for the app's own Gloved text
  scale compounded with the OS's own accessibility scaling (~1.5× nominal).
  `screens_responsive_test` is what actually proves it fits, not the numbers
  themselves.
- **Pass `startCollapsed` when the viewport is already short.** Scroll
  position starts at zero, so without it a compact-height screen (landscape;
  the keyboard up) would spend the full expanded extent on first paint,
  before anything has been scrolled — exactly the space this exists to buy
  back. Screens pass whatever "not enough room" condition they already use
  elsewhere — `context.isCompactHeight`, or Scan's own `tight`.
- **A sliver only builds what's near the viewport.** A widget test that taps
  or reads text placed in a trailing sliver — the bottom action bar,
  especially — has to scroll it into view first, or the finder returns
  nothing. See `scrollUntilVisible` in `demo_path_test.dart`.

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
