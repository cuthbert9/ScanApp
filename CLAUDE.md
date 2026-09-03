# scanapp — engineering guide for AI and humans

> Claude Code loads this file automatically on every session. It is the entry
> point for the workflow in `.claude/`. Keep it accurate: a stale rule here
> silently teaches the wrong pattern to every future session.

## Workflow: plan before you execute

**Always present an implementation plan and get explicit approval before
editing any file.** This is the project's first rule; everything below assumes
it.

This is enforced, not merely requested. `.claude/settings.json` sets
`permissions.defaultMode: "plan"`, so sessions start in plan mode and file
edits are **blocked** until a plan is approved. Reading, searching and running
read-only commands to research the plan are all still available — investigate
as much as you need first. `.claude/hooks/plan-first.py` re-states the rule if
a session has since left plan mode.

### What a plan must contain

1. **What and why** — the change in a sentence or two, and the problem it
   solves.
2. **Files** — exact paths, each marked create / modify / delete. Vague scope
   is the main reason a plan gets approved and then surprises everyone.
3. **Approach** — the design, and any trade-off that is genuinely a decision
   rather than an obvious default. Recommend one option; do not present a
   survey.
4. **Out of scope** — what you are deliberately *not* touching. This is the
   most valuable line in most plans.
5. **Verification** — the commands that will prove it works
   (`flutter analyze`, `flutter test`, a specific manual check on-device).
6. **Device impact** — how the change behaves on the MC9450: does it fit at
   320×533 and rotated, is it reachable with gloves, does it work from the
   hardware trigger and keypad without the touchscreen. Say "no device impact"
   when there genuinely is none, rather than omitting it.
7. **Assumptions and open questions** — anything you had to guess. If a guess
   would be expensive to get wrong, ask before planning further rather than
   burying it here.

### Proportionality

A plan is a decision aid, not a ceremony. Scale it to the work:

- **Typo, one-line tweak, a question** — no plan. Say in one line what you are
  about to do, then do it.
- **A new widget, a bug fix** — a short paragraph and a file list.
- **A feature, a refactor, anything touching the design tokens or the folder
  structure** — the full seven points above.

Padding a trivial change into a formal plan wastes a review cycle and trains
the reader to skim. Under-planning a structural change costs far more.

### After approval

Build what was approved. If the work reveals that the plan was wrong — a file
that does not exist, an approach that will not work — **stop and say so**
rather than quietly substituting a different design. A plan that changed
without being re-approved is no longer a plan.

## Current state — read this first

The repo is a **bare Flutter scaffold**: `lib/main.dart` and nothing else. None
of the modules named below exist yet.

So treat every path in this document as the **agreed destination**, not as
something you can import today. When you first need one, create it at exactly
the path given here — that is what keeps the structure from fragmenting across
sessions. Do not invent an alternative layout, and do not create a folder
before it holds real code.

The packages below are likewise **not installed yet**. Install them on first
use, in one go:

```
flutter pub add flutter_riverpod riverpod_annotation go_router freezed_annotation json_annotation
flutter pub add dev:build_runner dev:riverpod_generator dev:freezed dev:json_serializable
```

Note: `riverpod_lint`/`custom_lint` are deliberately **not** used — they lag
Riverpod 3 and force Freezed back to 2.x. The hooks in `.claude/hooks/` and the
rules here cover that ground instead.

## What this app is

A Flutter app for **Zebra MC9450 rugged handhelds** — warehouse/industrial data
capture. This single fact drives most decisions below, so internalise it:

| Constraint | Consequence |
|---|---|
| ~320 × 533 dp canvas (800×480 @ ~1.5 density, 4.3") | Lean chrome. A phone layout will not fit. Never assume ≥360 dp width. |
| Operated with **gloves** | 56 dp touch targets for primary actions, 48 dp absolute floor. |
| Bright sun *and* dim aisles | High-contrast semantic colors. Never rely on subtle tints alone. |
| **Hardware trigger + physical keypad** | Scanning must never *require* an on-screen tap. Every action reachable by key. Focus rings must be obvious. |
| Hundreds of scans per shift | Animations are latency. Nothing may block the next scan. |
| Barcode payloads are read by eye | Render codes/SKUs/serials in the monospace `data*` styles. |

Scanning arrives via **Zebra DataWedge intent broadcasts**, not a camera preview.

### Check every change against the device

This is not background reading. **Every plan and every implementation is
checked against this list** — most of what makes this app different from a
generic Flutter app is here, and none of it is visible from the code alone.

- [ ] **Fits 320×533 dp**, and still fits rotated (533×320) and with the
      keyboard up (~280 dp of height). See rule 1c.
- [ ] **Reachable with gloves** — 56 dp for anything tapped in a hurry, 48 dp
      floor.
- [ ] **Readable in sun and in a dim aisle** — semantic status colours, not
      subtle tints. Check both themes.
- [ ] **Works without the touchscreen.** The device has a hardware trigger and
      a physical keypad. Scanning must never *require* an on-screen tap, every
      action must be key-reachable, and focus must be visibly obvious.
- [ ] **Survives the scan loop.** Hundreds of scans a shift: no animation or
      dialog may gate the next scan, and nothing may accumulate per scan
      (listeners, controllers, growing lists) without being disposed or bounded.
- [ ] **Barcode data is monospaced** — codes, SKUs, serials and LPNs are read
      and compared by eye.
- [ ] **Degrades off-network.** Warehouse Wi-Fi has dead zones. A failed call
      must leave the operator able to keep working, not stuck on a spinner.

When a requirement and the device conflict, say so rather than quietly
choosing. "This form needs six fields but only three fit in landscape" is
information the person asking needs.

Backend: **UI first.** A separate repo serves MSSQL over HTTP; this app only
calls those endpoints. Until they exist, features run against fakes behind a
repository interface — never against a half-real client.

## Stack (agreed, install on first use)

Flutter 3.47 / Dart 3.13 · Riverpod 3 (`@riverpod` codegen) · Freezed 4 ·
go_router · `flutter_lints`.

These versions are verified to resolve together against Flutter 3.47.

Syntax that differs from most tutorials online — get these right:

```dart
// Freezed 4 — `abstract class`, and `with _$X`
@freezed
abstract class Foo with _$Foo {
  const factory Foo({required String id}) = _Foo;
  factory Foo.fromJson(Map<String, Object?> json) => _$FooFromJson(json);
}

// Riverpod 3 generator — the ref is a plain `Ref`, not `FooRef`
@riverpod
Future<Foo> foo(Ref ref) async => ...;
```

After touching any `@freezed` / `@riverpod` / `@JsonSerializable` file:

```
dart run build_runner build --delete-conflicting-outputs
```

Generated files (`*.g.dart`, `*.freezed.dart`) are **git-ignored** — they are
build output, and committing them creates constant merge conflicts. A fresh
clone runs `flutter pub get && dart run build_runner build` before it compiles.

## The core rules

Everything else in this document is an elaboration of these.

### 1. Design tokens are the single source of truth

The UI has **three layers**, and code may only read *downward*:

```
Layer 1  primitive tokens   raw values      lib/core/design/tokens/
Layer 2  semantic tokens    named by role   lib/core/design/extensions/
Layer 3  component theme    ThemeData       lib/core/design/theme/
```

**Screens and widgets read Layer 2 only**, through `BuildContext`:

```dart
context.colors.surface      context.spacing.md     context.radii.card
context.type.bodyMd         context.sizes.iconMd   context.motion.feedback
```

Forbidden anywhere under `lib/features/**` and `lib/shared/**`:

| Never write | Write instead |
|---|---|
| `Color(0xFF...)`, `Colors.red` | `context.colors.danger` |
| `EdgeInsets.all(16)` | `EdgeInsets.all(context.spacing.lg)` |
| `TextStyle(fontSize: 14)` | `context.type.bodyMd` |
| `BorderRadius.circular(12)` | `context.radii.cardBorder` |
| `Duration(milliseconds: 200)` | `context.motion.transition` |
| `SizedBox(height: 8)` | `SizedBox(height: context.spacing.sm)` |
| `Theme.of(context).colorScheme.x` | `context.colors.x` |

A hook enforces this (`.claude/hooks/design-token-guard.sh`). If a value you
need does not exist as a token, **add the token** — do not inline the literal.
Adding one is a deliberate act: see `/design-token`.

*Why:* re-theming, dark mode, and a future high-contrast sunlight mode become a
change to two files instead of a change to every screen.

### 1b. Style once, in the theme — never at the call site

Tokens stop you writing `16`. They do not stop you writing
`context.spacing.lg` in forty places. That is the *second* kind of duplicated
styling, and it hurts just as much: changing how buttons look still means
forty edits.

**So always push styling to the highest level that can carry it.** Before you
style anything, walk this ladder and stop at the first rung that works:

| Rung | Where | Use when |
|---|---|---|
| **1. Component theme** | `AppTheme` in `lib/core/design/theme/` — `FilledButtonThemeData`, `CardThemeData`, `InputDecorationTheme`, `AppBarTheme`, `ListTileThemeData`, … | The look applies to **every** widget of that type. Almost always the right answer. |
| **2. Shared widget variant** | `lib/shared/widgets/` — a new value on the widget's variant enum | Style and behaviour travel together, and several features need it. |
| **3. Call site** | `.copyWith(...)` in the screen | A genuine one-off, appearing exactly once. |

The rule that decides it: **if you write the same styling twice, it belongs one
rung up.** The second occurrence is the signal — not the fifth.

Practical consequences:

- A plain `FilledButton(...)` with no `style:` must already look right. If it
  does not, fix `AppTheme`, not the call site.
- `FilledButton.styleFrom(...)` or `ButtonStyle(...)` in a screen is usually
  rung 1 work done in the wrong place — it silently diverges from every other
  button the moment the theme changes.
- Prefer starting from `context.type.<style>` and `.copyWith(color: ...)` over
  building a `TextStyle(...)` from scratch.
- A one-off `Container` decoration that starts looking like a card is telling
  you it should be an `AppCard`.

#### Inline styling is fine for genuinely exceptional cases

This rule is about stopping *repetition*, not about banning inline style. Some
things really are one of a kind, and forcing them into the theme makes the
theme worse — it fills up with entries used once, which is its own kind of mess.

Inline styling is the right call when:

- The element is genuinely unique and appears **exactly once** — a splash or
  onboarding illustration, an empty-state graphic, a one-off hero panel.
- You are deliberately breaking the pattern for emphasis, and the break *is*
  the point — a single destructive confirmation, a hard-stop error screen.
- A third-party widget cannot read `AppTheme` and must be styled at the call
  site.
- The value is computed at runtime and cannot be a static token — an
  interpolated colour, a progress-driven dimension, an animated size.
- It is a debug, diagnostic or developer-only screen that operators never see.

**Mark it so it stays deliberate.** Write `// style-ok: <short reason>`. The
hook then allows it, and the reason tells the next reader — or the next
session — that this was a decision rather than an oversight.

The marker has two scopes:

```dart
// Trailing on a line — covers that one line.
Text('47', style: TextStyle(fontSize: 44)), // style-ok: one-off hero numeral

// Standalone comment — covers the block that follows, to the next blank line.
// Useful inside a multi-line widget, where the offending line is buried.
// style-ok: vendor widget cannot read AppTheme
FilledButton(
  style: FilledButton.styleFrom(backgroundColor: context.colors.danger),
  onPressed: _confirm,
  child: const Text('Delete'),
),
```

A standalone marker stops after 15 lines, so it can never quietly exempt a
whole file.

The one thing that is never acceptable is an **unmarked** exception, or the
same "exception" appearing twice. A second occurrence is no longer special —
promote it to rung 1 or 2.

*Why this comes before convenience:* the app will grow to dozens of screens on
a device whose palette may well need a high-contrast sunlight variant later.
Styling held in the theme makes that a one-file change. Styling sprayed across
screens makes it a rewrite.

### 1c. Every screen must be responsive

The app has one primary target, so it is tempting to lay out for exactly
320×533 dp and move on. That breaks immediately, because the canvas is not
fixed even on the one device:

| What changes it | Result |
|---|---|
| **Rotation** | 533×320 — only **320 dp of height**. A form that fits in portrait will not fit here. |
| **On-screen keyboard** | Eats ~250 dp. On a 533 dp screen that leaves ~280 dp of content. |
| **Android font scaling** | Operators wearing safety glasses do turn it up. Every fixed-height box holding text overflows. |
| **The rest of the fleet** | MC9400 variants, and TC-series handhelds at 5–6" / 720×1280+. One codebase should serve them. |
| **Your dev machine** | Screens get built on macOS at 1200 dp wide. They must not look broken there either. |

So: **never lay out for a specific size.** Concretely —

- **No fixed dimensions for content.** Fixed sizes are for things that are
  genuinely fixed — icons, avatars — and those come from `context.sizes`.
  Everything else is sized by its content or by `Expanded` / `Flexible`.
- **Any column that could exceed the viewport must scroll.** In landscape,
  almost anything can. Use `ListView`, `SingleChildScrollView`, or
  `CustomScrollView`. A screen with a text field must scroll — no exceptions.
- **Text needs an escape route.** `maxLines` + `overflow: TextOverflow.ellipsis`,
  or wrap it in `Flexible`. A `Text` directly inside a `Row` is the single most
  common overflow in Flutter — give it `Expanded` or `Flexible`.
- **Decide from constraints, not from the device.** `LayoutBuilder` and
  `Flexible` respond to the space actually available. Branching on
  `MediaQuery.sizeOf(context).width > 600` hardcodes an assumption that a
  rotation or a split screen invalidates.
- **Never fix the height of a box containing text.** Text scaling will overflow
  it. Let it size itself, with `minHeight` from `context.sizes` if you need a
  floor.
- **`SafeArea`** around screen content, and keep
  `resizeToAvoidBottomInset: true` (the default) so the keyboard shrinks the
  viewport rather than covering the field.
- **Never put `Expanded` inside an unbounded parent.** `SingleChildScrollView`
  → `Column` → `Expanded` throws at runtime. Reach for
  `ConstrainedBox(minHeight:)` + `IntrinsicHeight`, or restructure.

`context.isCompactWidth` and `context.isCompactHeight` exist for *dropping
optional chrome*, not for forking layouts. Two layouts behind a size check is
two layouts to maintain, and one of them is always the stale one.

#### Verify it, do not assume it

An overflow is invisible until the exact moment it is not. Before calling a
screen done, check it at all four:

1. **Portrait** 320×533 — the real device.
2. **Landscape** 533×320 — where height-hungry layouts fail.
3. **Keyboard open** — focus a field and confirm you can still reach the
   submit button.
4. **Font scale 1.3** — `MediaQuery(data: ...copyWith(textScaler:
   TextScaler.linear(1.3)))`, or turn it up in Android settings.

In a widget test, pump the screen at several sizes and let a `RenderFlex
overflowed` error fail the test — Flutter reports overflow as a test failure,
so this is cheap to automate and catches regressions you would never
re-check by hand.

### 2. Check for an existing implementation before writing a new one

Before creating any widget, helper, extension, or model, **search first**:

```bash
rg -n "class .*Button" lib/shared/widgets/     # is there already one?
rg -n "extension .*on String" lib/core/        # already have this helper?
```

Then choose, in this order of preference:

1. **Use** the existing thing as-is.
2. **Extend** it with a new optional parameter or variant enum.
3. **Compose** it inside a thin new widget.
4. Create something new — only when the shape is genuinely different.

Two near-identical widgets is the failure mode to avoid. If you find yourself
copying a block of UI, stop and lift it into `lib/shared/widgets/`.

The bar for promoting to `lib/shared/`: **used by two or more features, and
contains no feature-specific logic.** One feature using it means it stays in
that feature.

### 3. Dependencies point inward, one direction only

```
features/  →  shared/  →  core/
```

- `core/` knows nothing about `shared/` or `features/`.
- `shared/` may use `core/`. It must not import any feature.
- A feature must **never** import another feature. If two need the same thing,
  it belongs in `shared/` or `core/`.

Within a feature, four folders with strict roles:

```
lib/features/<feature>/
  domain/         models + repository *interfaces*. Pure Dart, no Flutter.
  data/           repository *implementations*, DTOs, API/local sources.
  application/    Riverpod controllers. Orchestration, no widgets.
  presentation/   screens + feature-only widgets. No business logic.
```

`presentation/` never touches `data/` directly — it goes through
`application/`, which depends on the `domain/` interface. That is what makes
the fake-to-real backend swap a one-line provider override.

## Error handling

> `Result<T>`, `AppException` and `AppLogger` do not exist yet. Create them in
> `lib/core/result/`, `lib/core/errors/` and `lib/core/logging/` when the first
> repository needs them.

Repositories return `Result<T>` rather than throwing. Data sources translate
every transport error (`DioException`, socket, platform channel, SQL) into a
sealed `AppException` at the repository edge. Because both types are `sealed`,
the analyzer catches an unhandled failure case:

```dart
switch (result) {
  case Success<Item>(:final value): ...
  case Failure<Item>(:final error): ...
}
```

Never surface a raw exception message to an operator. `AppException.message` is
the operator-facing string; `cause` is for logs only.

Use `AppLogger`, never `print`.

## Definition of done

A change is not finished until all of these hold:

- [ ] `dart format .` and `flutter analyze` are clean.
- [ ] No hardcoded design values in `lib/features/**` or `lib/shared/**`.
- [ ] No styling repeated at call sites that belongs in `AppTheme` or a
      shared widget variant. Genuine one-offs are fine, marked
      `// style-ok: <reason>` (rule 1b).
- [ ] Screen checked in portrait, landscape, with the keyboard open, and
      at font scale 1.3 — no overflow, submit still reachable (rule 1c).
- [ ] Checked against the device list in 'What this app is' — gloves, keypad
      reachability, sunlight/dim legibility, scan-loop cost.
- [ ] No duplicate of something that already exists (rule 2).
- [ ] Codegen re-run if an annotated file changed.
- [ ] New artifact-producing tool → its outputs added to `.gitignore` in the
      same change.
- [ ] `ARCHITECTURE.md` updated if a feature, dependency, or convention changed
      (see `/docs-sync`).

## Workflow commands

| Command | Use it when |
|---|---|
| `/feature <name>` | Adding or extending a feature slice. |
| `/ui-component <name>` | Adding a reusable widget — checks for duplicates first. |
| `/design-token <what>` | A needed color/size/duration has no token yet. |
| `/docs-sync` | Refresh `ARCHITECTURE.md` after structural change. |

Sessions start in plan mode. `Shift+Tab` cycles permission modes if you need
to leave it; `/plan` forces a single prompt back into it.

## Conventions

- Files `snake_case.dart`; types `PascalCase`; members `camelCase`; `_private`.
- One public type per file, named after the file.
- Prefer `const` constructors — they are free performance on a low-end CPU.
- Widgets are **classes**, not `Widget _buildFoo()` methods. A method does not
  get its own element and defeats `const` and rebuild isolation.
- Keep `build()` shallow. Past ~3 levels of nesting, extract a private widget.
- `ConsumerWidget` over `StatefulWidget` unless you own an
  `AnimationController` or a `TextEditingController`.
- Document *why*, not *what*. The code says what it does.
