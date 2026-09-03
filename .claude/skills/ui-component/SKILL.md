---
name: ui-component
description: Add or modify a reusable widget in lib/shared/widgets/, after checking that an equivalent does not already exist. Use when a screen needs a button, card, banner, input, list row, empty state or similar building block.
---

# Add a reusable widget

The purpose of this skill is to make the *reuse check* unskippable. Most
duplicate code in Flutter apps enters through a widget someone did not know
already existed.

## 1. Prove it does not exist

```bash
ls lib/shared/widgets/*/
rg -n "class App[A-Z]" lib/shared/widgets/     # the shared vocabulary
rg -n "class .*<Noun>" lib/                    # near-matches anywhere
```

Then pick the cheapest option that works, and say which:

1. **Use** what exists unchanged.
2. **Extend** it — add an optional parameter or a variant to its enum.
   A `AppButtonVariant.danger` beats a whole new `DangerButton`.
3. **Compose** — wrap the existing widget in a thin, feature-local widget.
4. **Create new** — only when the shape is genuinely different.

If you are about to create something that shares more than half its build
method with an existing widget, that is option 2, not option 4.

## 2. Decide where it lives

| Condition | Location |
|---|---|
| Used by 2+ features, no feature-specific logic | `lib/shared/widgets/<group>/` |
| Used by exactly one feature | `lib/features/<f>/presentation/widgets/` |
| Wraps business logic | Not a shared widget. Rethink. |

Do not pre-promote. Move it to `shared/` on the day a second feature needs it.

## 2b. Ask whether this is a theme change, not a widget

Before writing a widget, check that the need is not already a theming problem.
A new widget whose only job is "the same thing but styled differently" is a
component theme or a variant, not a new class.

```bash
rg -n "ThemeData|ButtonThemeData|CardThemeData|InputDecorationTheme" lib/core/design/theme/
```

| What you are about to build | What it probably is |
|---|---|
| `PrimaryButton`, `DangerButton`, `SmallButton` | one `AppButton` + a variant enum, sized by `AppTheme` |
| A `Container` with a border, radius and padding | `CardThemeData`, or `AppCard` |
| A `Text` wrapper that sets a style | a `context.type.<style>` at the call site |
| "The same list row but with different padding" | `ListTileThemeData` |

If a plain, unstyled Material widget does not already look right in this app,
the fix belongs in `AppTheme` — every future use then inherits it for free.
Fixing it inside one new widget leaves every other instance wrong.

## 3. Write it

Non-negotiables:

- **Stateless and `const`-constructible** unless it owns a controller.
- **Every visual value from `context.*` tokens.** No literals — the hook
  rejects them, and they defeat theming.
- **Take styling from the theme, do not restate it.** Avoid `styleFrom(...)`
  and hand-built `TextStyle(...)`. If this widget needs a look that
  `AppTheme` does not already give it, change `AppTheme` (CLAUDE.md rule
  1b). A genuine one-off is allowed — mark it `// style-ok: <reason>` so
  it reads as a decision. A shared widget should rarely need one: if it is
  reusable, its styling is by definition not a one-off.
- **Variants via enum, not via boolean soup.** `AppButtonVariant.primary`,
  not `isPrimary` + `isDanger` + `isGhost`.
- **No Riverpod inside a shared widget.** It takes data and callbacks as
  parameters. A shared widget that reads a provider is coupled to one feature
  and stops being reusable.
- **Touch targets** default to `context.sizes.tapTargetComfortable` (56) for
  anything an operator taps in a hurry. `tapTargetMin` (48) is the floor.
- **Responsive by construction.** A reusable widget has no idea how much room
  its caller will give it, so it must never assume. No fixed width or height
  for content; `Text` gets `maxLines` + `overflow` or a `Flexible` parent; a
  `Text` inside a `Row` gets `Expanded`. Size from constraints
  (`LayoutBuilder`), never from `MediaQuery` device checks. A widget that only
  works at one width is not reusable (CLAUDE.md rule 1c).
- **Focus visible.** The MC9450 has a physical keypad; a control that cannot
  show focus is unusable without the touchscreen.
- **Doc comment** on the class saying when to use it *and when not to*.

Sketch:

```dart
enum AppBannerVariant { info, success, warning, danger }

/// A full-width status banner.
///
/// Use for state that persists on screen. For transient confirmation of a
/// scan, use a snackbar instead — a banner that appears and vanishes on every
/// scan is visual noise at 300 scans a shift.
class AppBanner extends StatelessWidget {
  const AppBanner({super.key, required this.message, this.variant = AppBannerVariant.info});
  ...
}
```

## 4. Export and verify

Add it to the barrel file for its group so screens import one path.

```bash
dart format . && flutter analyze
```

Render it narrow **and** wide before you call it done — a shared widget is the
worst place for a hidden overflow, because it fails in every screen that
adopts it. Check it at 320 dp wide, in a constrained `Row`, and at font scale
1.3.

Then check the reuse actually happened: replace the inline markup in the
calling screen with the new widget, and grep for other screens that should now
use it too.
