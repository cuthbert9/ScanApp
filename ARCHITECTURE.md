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
camera preview. That integration is **not built yet** — the on-screen scan
field is DataWedge's keyboard-wedge target in the meantime, not just a dev
stand-in (see "Scanning" below).

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

Pointing the app at a different backend host (for a sandbox/staging server)
doesn't need a code change:

```bash
flutter run --dart-define=API_BASE_URL=https://sandbox.example.com/erp-api
```

## Directory map

```
lib/
  main.dart                     ProviderScope + runApp. Nothing else.
  app/                          Composition root. Wiring only, no behaviour.
    app.dart                    MaterialApp.router, theme mode, text scale.
    router/routes.dart          Every path as a constant.
    router/app_router.dart      GoRouter, the auth guard, the tab branches.
    state/                      App-level stores every screen watches —
                                 dock_controller.dart (staged orders, the open
                                 order), sync_controller.dart (the outbox),
                                 preferences_controller.dart (theme/text size).

  core/                         Depends on nothing else in the app.
    design/                     The design system. See below.
    errors/app_exception.dart   Sealed failure vocabulary.
    result/result.dart          Sealed Result<T> = Success | Failure.
    network/                    The real HTTP stack: api_config.dart (base URL,
                                 timeouts), api_client.dart (the one Dio
                                 instance + bearer-token interceptor),
                                 dio_error_mapper.dart (DioException →
                                 AppException). Never imports `features/` —
                                 it takes its token via a callback, wired at
                                 the composition root (see below).
    storage/token_store.dart    Secure-storage wrapper for the persisted
                                 session's raw fields. Untyped by design, for
                                 the same reason as `network/`.

  domain/                       The shared aggregate and the contracts.
    models/                     Order (+lines), Officer, Station, Vehicle,
                                 ScanEvent, LoadSeal, SyncRecord/Status,
                                 ColdChainLog, ShiftStats, Gs1Barcode — the
                                 mock-backed aggregate — plus LoadPlan,
                                 LoadPlanItem, Truck, ItemLookupResult,
                                 OperatorProfile, AppRemoteConfig — the real
                                 backend's models, deliberately separate (see
                                 "Two aggregates" below). Pure Dart.
    repositories/                Eleven interfaces: the seven original
                                 (Order/Scan/Load/Sync/Station/Officer/
                                 Settings, backed by MockBackend) plus
                                 AppConfig/Operator/LoadPlan (real HTTP). Every
                                 one is a `SWAP POINT` — see the doc comment on
                                 each interface.

  data/                         Repository implementations, plus the mock
                                 store and the composition root.
    mock_seed.dart               Every seed value for the mock backend. Edit
                                 this to change scenarios.
    mock_backend.dart            The single in-memory store + all its rules
                                 (scan ladder, FEFO, sealing).
    mock_*_repository.dart       Thin adapters over MockBackend: latency in,
                                 Result out.
    http_app_config_repository.dart
    http_operator_repository.dart
    http_load_plan_repository.dart
                                 Real implementations of the three read-only
                                 SCN repositories — see "The real backend"
                                 below for exactly what's wired where.
    repository_providers.dart    Provider wiring for the seven mock-backed
                                 repositories.
    network_providers.dart       The composition root for networking: Dio,
                                 ApiClient, TokenStore, AuthRepository, and the
                                 three real SCN repositories. The one file
                                 allowed to import both `core/` and `features/`
                                 for wiring purposes.

  shared/widgets/               Reusable, feature-agnostic widgets.
    display/                    AppBadge, AppDetailRow, AppMetaRow,
                                AppSectionHeading, AppStatRing, AppStatTile,
                                AppSummaryCompactLine
    feedback/                   AppInfoPanel, PlaceholderScreen
    layout/                     AppScreenHeader, AppSummaryStrip,
                                AppBottomActionBar, AppPinnedSummary
    widgets.dart                Barrel — import this, not individual files.

  features/                     **Presentation and per-screen controllers.**
    auth/                       Sign-in — real, against the ERP's general auth
                                 endpoint. The one feature with its own
                                 `domain/`+`data/` (Session, AuthRepository,
                                 HttpAuthRepository) — see "The real backend".
    orders/                     The loading queue (home tab). Still mock-backed.
    loading/                    Scan & Verify and Load Reconciliation. Still
                                 mock-backed.
    sync/                       Offline Sync. Still mock-backed.
    settings/                   Operator, shift figures, station, preferences.
                                 Still mock-backed.
    shell/                      Bottom-tab chrome around the branches.
```

`auth/` is the only feature carrying its own `domain/`/`data/` folders — its
`Session`/`AuthRepository` are used nowhere else, so they had no reason to
join the shared `domain/`/`data/` at the top level the way the seven
mock-backed models did.

## The real backend

Base URL: `https://www.mag-erp.com/erp-api` (production; override with
`--dart-define=API_BASE_URL=...`). Bearer-token auth throughout.

**Fully wired, end to end:**

| What | How |
|---|---|
| Sign-in | `LoginScreen` → `AuthController` (`AsyncNotifier<Session?>`) → `HttpAuthRepository` → `POST /v2/auth/login`. Session (incl. refresh token) persisted via `TokenStore` (`flutter_secure_storage`), restored on relaunch. `operatorId` comes straight from the login response's `user.id` — confirmed to be the same identity the SCN endpoints call `operatorId`. |

**Implemented and provider-wired, but not yet read by any screen** — real,
callable, correct against the confirmed response shapes, waiting on the
Orders/Scan/Load screens to move off `Order`/`OrderLine` before there's
anywhere to plug them in:

| Repository | Endpoint(s) |
|---|---|
| `AppConfigRepository` | `GET /v2/scn/app/config` — response shape unconfirmed (no example has ever been seen for it, live or documented), so `AppRemoteConfig` is a raw passthrough map rather than named fields. |
| `OperatorRepository` | `GET /v2/scn/operators/{operatorId}` |
| `LoadPlanRepository` | `GET .../operators/{operatorId}/load-plans`, `GET .../load-plans/{id}`, `GET .../load-plans/{id}/items`, `GET .../items/by-barcode/{barcode}` |

**Still entirely mock-backed** — `OrderRepository`, `ScanRepository`,
`SyncRepository`, `StationRepository`, `OfficerRepository`,
`LoadRepository`, `SettingsRepository`. Wiring `ScanRepository`/
`SyncRepository` for real needs a real `loadPlanId`, which only exists once
the queue screen reads `LoadPlanRepository` instead of `OrderRepository` —
building the write path first would have nothing real to submit against.
`SettingsRepository` is not expected to become HTTP at all: preferences are
device-local by definition (see its own doc comment).

`Officer` (staff number, grade, shift window) has no equivalent in the real
operator payload (`id, username, name, role` only) — `OperatorProfile` exists
as the honest, separate model rather than fabricating the missing fields onto
`Officer`.

## Dependency rule

```
features/  →  shared/  →  core/
```

One direction only. `core/` knows nothing above it — including `core/network`,
which takes its bearer token via a callback rather than importing
`features/auth` directly. `shared/` may use `core/` but no feature; **a
feature never imports another feature**. If two need the same thing, it moves
down into `shared/` or `core/`. `lib/data/` is the composition root and is the
one place allowed to import across `domain/`, the mock store, the real HTTP
repositories, and (in `network_providers.dart`) `features/auth`.

Inside `features/auth/` specifically:

| Folder | Holds | May not |
|---|---|---|
| `domain/` | `Session`, the `AuthRepository` interface. Pure Dart. | Import Flutter |
| `data/` | `HttpAuthRepository` | Leak `DioException` past its own boundary |
| `application/` | `AuthController` | Contain widgets |
| `presentation/` | `LoginScreen` | Contain business logic |

The other features (`orders/`, `loading/`, `sync/`, `settings/`) don't carry
`domain/`/`data/` — they read the shared aggregate in `lib/domain/`/`lib/data/`
instead, per rule 3: two or more consumers of the same model is what moves it
down a level.

## Design system

Three layers, in `lib/core/design/`. Code reads **downward only**.

| Layer | Location | What |
|---|---|---|
| 1 Primitives | `tokens/primitive_tokens.dart` | Raw ramps and scales. The only literals in the app. |
| 2 Semantic | `extensions/` | Colour roles + spacing, radii, sizes, type, motion, as `ThemeExtension`s. |
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

The guard in `app_router.dart` follows `AuthController`'s `AsyncValue<Session?>`
rather than a bare bool — signed-in is `.value != null`, checked via a
`ValueNotifier<bool>` the router listens to (built once, so it cannot
`ref.watch`).

`indexedStack` gives each tab its own navigator, so switching away and back
preserves scroll position — losing your place in a long queue mid-shift is a
real cost on this device.

## Feature inventory

| Feature | Owns | Entry | State |
|---|---|---|---|
| `orders` | The dock's loading queue: staged orders, counts, selection | `LoadingQueueScreen` | Mock-backed |
| `loading` | Scanning units onto a truck, judging them against the manifest, and reconciling before seal | `ScanScreen`, `LoadReconciliationScreen` | Mock-backed, incl. sealing |
| `sync` | Presentation for the outbox — mode selection and flushing | `SyncScreen` | Mock-backed, incl. flush |
| `settings` | The operator, shift figures, the station, and the preferences that apply | `SettingsScreen` | Mock-backed, incl. station picker |
| `auth` | Sign-in and the session | `LoginScreen` | **Real** — calls the ERP's login endpoint |
| `shell` | Bottom-tab chrome | `AppShell` | Complete |

## One aggregate, one store (the mock side)

`lib/domain/models/order.dart` carries `lines[]`, and every figure is derived
from them. Units, verified, held, short, first-pass yield, weight and volume
are all getters on the aggregate, so changing one line's `state` moves every
number on every screen at once. Nothing downstream recomputes or caches them.

`DockController` in `app/state/` is the app-level store: it holds the staged
orders, the open order and the `hasViewedLoad` flag. Every mutation goes
through a repository and then `refresh()`, which is why the queue card behind
the Scan screen is already correct when you go back to it.

`ScanFeed` (`features/loading/application/scan_controller.dart`) is the scan
feed for whichever order is open. `simulate()` stands in for a hardware
trigger pull; `scanCode(String rawCode)` reproduces a specific
duplicate/wrong-order/FEFO outcome deliberately. Both funnel through
`_record`, which is "one mutation, three refreshes" — the feed, the dock
(moving every figure on Orders/Scan/Load at once), and the outbox (moving the
tab badge and the header dot).

## The outbox

The outbox lives behind `SyncRepository` and is held by `SyncController` in
`app/state/`. Three unrelated places read it: the shell's tab badge, the amber
dot on every screen header, and the Sync screen.

`pendingSyncCountProvider` is derived from the queue, so a flush empties all
three at once and none can go stale. Every scan and every seal enqueues a
record, which is why the badge moves when you scan. **This queue is still
mock-only** — see "Not built yet".

## One feature, two tabs

`features/loading/` serves both the SCAN and LOAD tabs, because they are two
views of one aggregate: a delivery order going onto a truck. Scan captures it,
Load reconciles it. Splitting them into separate features and then sharing the
session between them would have meant a feature-to-feature import, which rule
3 forbids.

## Scanning

The on-screen scan field (`features/loading/presentation/widgets/scan_input_field.dart`)
is DataWedge's **keyboard-wedge** target: DataWedge in keyboard-wedge mode
types the decoded barcode into the focused field and sends Enter, so on a real
MC9450 this receives genuine hardware scans with no native code required. It
stays useful afterwards too, because warehouse labels get torn and someone has
to key the number in. A native intent-broadcast bridge (`ScannerService`) is
the eventual real path but is **not built yet** — nothing downstream would
need to change when it lands, since it would feed the same `scanCode` entry
point the field calls today.

`Gs1Barcode.parse` (`lib/domain/models/gs1_barcode.dart`) decodes both the
bracketed form `(00)…(10)…(17)…` and raw concatenated scanner output, using
FNC1 separators for variable-length AIs. It never throws: an undecodable code
still produces a feed row, because a scanner that appears to do nothing is
worse than one that reports a problem.

`MockBackend.scanCode`'s rule ladder is applied most-specific-first — already
scanned, then wrong order, then FEFO hold — so "you already scanned this"
beats a generic rejection. The real backend's bulk-sync endpoint returns a
per-scan accepted/duplicate/invalid verdict of its own once wired (see "Not
built yet") — the client-side ladder is what keeps scanning working with no
link in the meantime, not a permanent duplicate of server logic.

## Data and errors

Repositories return `Result<T>`, never throw. On the mock side, data sources
translate `StateError`s from `MockBackend` into a sealed `AppException` at the
repository edge. On the real side, `mapDioError` (`core/network/`) does the
same for `DioException` — a timeout or connection error becomes
`NetworkException`, a 401/403 becomes `AuthException`, a 400/404/409 becomes
`ValidationException`, anything else `ServerException`. Either way, UI never
sees a `DioException`, a `PlatformException`, or a raw `StateError`. Both
`Result` and `AppException` are `sealed`, so the analyzer catches an unhandled
case.

Controllers unwrap the `Result` and rethrow the exception, which Riverpod
turns into `AsyncError`. Widgets therefore deal only in `AsyncValue` and
render `AppException.message` — written for an operator — never the raw
error.

### Swapping in the real backend

Every repository is provided in exactly one place — `repository_providers.dart`
for the seven mock-backed ones, `network_providers.dart` for the four real
ones — and every screen reads the interface. Point a provider at a different
implementation and nothing above it moves:

```dart
// lib/data/network_providers.dart
@Riverpod(keepAlive: true)
LoadPlanRepository loadPlanRepository(Ref ref) =>
    HttpLoadPlanRepository(ref.watch(dioProvider));
```

Tests override the same providers — `test/support/fake_auth_repository.dart`
is a `FakeAuthRepository` used by widget tests that need to start signed in
without hitting the real login endpoint.

## Testing

44 tests, four files:

| File | Covers |
|---|---|
| `mock_backend_test.dart` | The rules, directly — the scan ladder in order, FEFO, sealing amended, a sealed order refusing scans, flushing, air-gapped refusal, simulated offline, station re-sync. No widgets. |
| `gs1_barcode_test.dart` | The GS1 parser — bracketed, concatenated, FNC1, bare EANs, expiry edge cases, malformed input. |
| `demo_path_test.dart` | The whole mock-backed flow through the real router and shell: sign in (via `FakeAuthRepository`), open an order, debug-scan, reconcile, seal, watch it leave the queue, flush the badge, switch theme. |
| `screens_responsive_test.dart` | All five tabs at portrait, landscape, and both at font scale 1.3, asserting no `RenderFlex overflowed`; plus a simulated-status-bar sweep asserting every screen's scrollable viewport starts below the inset. |

Rules are tested at the backend rather than through widgets, which is the
whole point of keeping them there. The demo path is the integration test; the
responsive sweep is the layout safety net.

Test-authoring traps worth remembering:

- Inside `testWidgets` the clock is faked, so awaiting a repository future
  before any `pump()` never completes.
- Widget tests that need a signed-in operator override `authRepositoryProvider`
  with `FakeAuthRepository`, not a bare `AuthController.signIn()` call — that
  method now performs a real network round trip and takes `(email, password)`.
- The shell's `IndexedStack` keeps every screen mounted, so a bare
  `find.byType(CustomScrollView)` (or `ListView`) matches several — scope
  finders to the screen you mean.
- Every screen is one scrolling sliver list, so a widget placed near the
  bottom — the bottom action bar most of all — is not built until scrolled
  near the viewport; `find` on it returns nothing until then, not a
  "not visible yet" hint.
- `Semantics(label: ..., child: ...)` merges with a descendant's own implicit
  label unless it also sets `excludeSemantics: true` — worth an exact-match
  sanity check (`find.bySemanticsLabel('X')`, not just `find.byIcon(...)`)
  whenever a "walk every tab" helper is added anywhere.
- Forcing a full-tree teardown mid-test (`pumpWidget(const SizedBox())`, to
  unmount and dispose everything) can race a `Timer`/provider callback that
  was already in flight — Riverpod's fix is `if (!ref.mounted) return;` right
  after the `await`, before touching `state`. Not a test-only workaround: the
  same race exists on a real device the instant the app is killed mid-tick.

## Decisions

| Decision | Why |
|---|---|
| **Riverpod 3 + codegen** | Compile-safe DI, least boilerplate, and provider override is the backend swap seam. |
| **Generated files git-ignored** | `*.freezed.dart` / `*.g.dart` are build output; committing them causes constant merge conflicts. Cost: codegen before first run. |
| **No `riverpod_lint` / `custom_lint`** | They lag Riverpod 3.4 and would force Freezed back to 2.x. The hooks in `.claude/hooks/` cover that ground. |
| **DataWedge natively, not `flutter_datawedge`** | The package is well behind current Flutter. DataWedge is only intent broadcasts, so a small Kotlin BroadcastReceiver behind a `ScannerService` interface avoids the dependency risk. Not built yet. |
| **`dio` over `package:http`** | Interceptors (bearer-token injection) and a typed exception (`DioException`) that maps cleanly onto `AppException`, without hand-rolling either. |
| **`ApiClient` takes a token callback, not `AuthRepository`** | Keeps `core/network` free of any `features/` import (the dependency rule), at the cost of one indirection wired in `network_providers.dart`. |
| **New `LoadPlan`/`LoadPlanItem`/`OperatorProfile` models rather than reusing `Order`/`Officer`** | The real payloads don't carry `Order`'s vehicle/bay/route/cold-chain fields or `Officer`'s staff number/grade/shift window. Forcing them in would mean fabricating data that doesn't exist server-side yet. |
| **Real SCN read repositories wired before any screen consumes them** | Verifying the data layer against the confirmed API shapes first, independently of the larger Orders/Scan/Load screens rewrite that moving off `Order` requires. |
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

Everything returns when the keyboard closes. Both flags come from `context`
helpers in the design layer, so the size comparisons live in one place.

## Screen chrome: scrolling header, pinned dashboard

All five tabs share the same shape: the whole screen is one `CustomScrollView`,
not a `Column` of fixed chrome around a scrolling body.

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

Four things worth knowing before touching this:

- **A `SliverPersistentHeader` needs a concrete pixel extent** — the one place
  a box holding text has a fixed height, which rule 1c otherwise forbids.
  `AppSizes.summaryStripExpandedHeight` / `summaryStripCollapsedHeight` /
  `scanProgressStripExpandedHeight` are each the strip's real, unstretched
  content height at text scale 1.0 — not padded upfront. `AppPinnedSummary`
  scales both extents live by the device's actual text scale, so the common
  case stays exactly this size and only grows when text actually does.
- **Pass `startCollapsed` when the viewport is already short.** Scroll
  position starts at zero, so without it a compact-height screen (landscape;
  the keyboard up) would spend the full expanded extent on first paint.
  Screens pass whatever "not enough room" condition they already use
  elsewhere — `context.isCompactHeight`, or Scan's own `tight`.
- **A sliver only builds what's near the viewport.** A widget test that taps
  or reads text placed in a trailing sliver — the bottom action bar,
  especially — has to scroll it into view first, or the finder returns
  nothing. See `scrollUntilVisible` in `demo_path_test.dart`.
- **`AppScreenHeader` carries no top-safe-area padding of its own.** Each
  screen wraps its whole `CustomScrollView` in `SafeArea(top: true, bottom:
  false)` instead, so a pinned strip that ends up at the very top of the
  viewport is still protected from the status bar.

## Charts

`WeeklyScanChart` is the only data visualisation, and it follows the project's
dataviz rules rather than taste:

- **One series**, so no legend — the title names it. Today is an emphasised
  mark *within* the series, not a second series.
- **Colours were validated, not picked.** `chartBar` and `chartBarEmphasis`
  were run through the palette checker as a one-hue ordinal ramp against each
  theme's card surface. The passing steps are `#C8A227`/`#876A16` on light and
  `#A8861C`/`#DCBB5C` on dark.
- The dark steps are **chosen, not flipped**: on a dark card the *lighter*
  step is the prominent one.
- Every value is reachable as text too — a caption line, a per-bar semantic
  label, and tap-to-inspect. **Tap replaces hover**, which does not exist on a
  gloved handheld.

Re-run the checker before changing any chart colour; do not eyeball it.

## Not built yet

- **DataWedge intent bridge.** No `ScannerService`, no native
  BroadcastReceiver, no hardware-trigger handling. Keyboard-wedge mode already
  works through the scan field, so the device is usable before this lands.
  **Keypad focus order is still unwired** — every action is reachable by
  touch, and the scan flow works from the keypad, but tab order elsewhere is
  not set.
- **Scan submission and offline sync are still mock-only.** `ScanRepository`
  and `SyncRepository` are not wired to `POST .../load-plans/{id}/scans` or
  `POST /v2/scn/sync/scans` yet — that needs the queue/scan screens to read
  `LoadPlanRepository` (real GUIDs) instead of `OrderRepository` first.
- **The Orders/Scan/Load screens don't read the real backend.** `LoadPlan`/
  `LoadPlanItem`/`Truck`/`ItemLookupResult` exist and are provider-wired, but
  no screen consumes them — they still show `MockBackend`'s `Order` data.
- **`GET /v2/scn/app/config`'s response shape is unconfirmed.** No example has
  ever been seen, live or documented, so `AppRemoteConfig` is a raw
  passthrough map rather than typed fields.
- **Nothing is encrypted at rest beyond the session.** The signed-in session's
  token/refresh-token live in `flutter_secure_storage`; everything else (sync
  queue, scan feed, preferences) is still an in-memory mock store that resets
  on restart.
- **No dispatch map.** The station card carries the base details on their own.
- **`Change station` has no destination**, and the scanner and session cards
  on Settings are display-only.
- **`Seal load` is a no-op against a real backend** — it only mutates
  `MockBackend`'s in-memory state.
- Vehicle capacities are fixed constants; there is no fleet lookup.
- The cold-chain temperature and door-open readings are fake, and have no
  backing endpoint in the real API at all yet.
