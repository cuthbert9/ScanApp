---
name: design-token
description: Add, rename or change a design token (color, spacing, radius, type style, size, duration) in lib/core/design/. Use when a needed visual value has no token yet, or when the design-token hook has rejected a literal.
---

# Change the design system

> **If `lib/core/design/` does not exist yet**, this skill is how you create
> it. Build all three layers in one pass — a half-built token system is worse
> than none, because screens start routing around the gaps. The device
> constraints at the bottom of this file are the spec for the initial values.

Tokens are the single source of truth for the app's appearance. A change here
reaches every screen at once — which is the point, and also why it deserves a
moment's thought.

## The three layers

```
Layer 1  lib/core/design/tokens/       raw values      PrimitiveColors.blue500
Layer 2  lib/core/design/extensions/   named by ROLE   AppColors.primary
Layer 3  lib/core/design/theme/        ThemeData       FilledButtonThemeData
```

UI reads **Layer 2 only**, via `context.colors` / `spacing` / `radii` / `sizes`
/ `type` / `motion`.

## Which layer are you changing?

**"This blue is slightly wrong."** → Layer 1. Change the ramp value. Every
semantic role pointing at it updates.

**"Cards should use the brand color instead of the neutral surface."** → Layer
2. Repoint the role at a different primitive. Add no new primitive.

**"I need a value that has no name yet."** → Ask first: is it genuinely a new
*role*, or an existing role you have not found?

```bash
rg -n "final Color " lib/core/design/extensions/app_colors.dart
rg -n "final double " lib/core/design/extensions/app_spacing.dart
```

Most of the time the role exists. Adding `cardBackgroundV2` next to `surface`
is how a token system dies.

**"Buttons should be taller everywhere."** → Layer 3, or the size token feeding
it. Never restyle buttons at a call site.

**"This widget needs to look different."** → Layer 3 first. Reach for the
component theme (`FilledButtonThemeData`, `CardThemeData`,
`InputDecorationTheme`, …) before you touch a screen. A styling change made
in `AppTheme` reaches every instance; the same change made at a call site
reaches one and silently diverges from the rest. Only a genuine one-off
belongs in a screen — and a one-off that appears twice is no longer one.

## Adding a semantic token — the full checklist

A `ThemeExtension` has four places that must stay in sync. Miss one and it
fails at runtime, not compile time:

1. `final` field declaration + doc comment saying what it is **for**.
2. Constructor parameter (`required this.x`).
3. **Both** `light` and `dark` constants.
4. `copyWith`.
5. `lerp`.

Then verify:

```bash
dart format . && flutter analyze
```

## Naming

Name by **role**, never by appearance or by the component that first used it.

| Good | Bad | Why |
|---|---|---|
| `danger` | `red` | The role survives a rebrand; the hue does not. |
| `surfaceSunken` | `greyBg` | Describes intent, not a color. |
| `tapTargetComfortable` | `size56` | The number can change; the meaning cannot. |
| `scanListening` | `blueGlow` | A future session can tell when to use it. |

If you cannot name it by role, you probably do not need a new token.

## Device constraints these tokens encode

Do not casually undo these — each exists for a reason:

- `screenPadding` is 12, not 16. The canvas is ~320 dp wide; 16 dp gutters cost
  10% of usable width.
- `tapTargetComfortable` is 56, above Material's 48. Operators wear gloves.
- `borderFocus` is 3 dp. Focus must be obvious for physical-keypad navigation.
- Type sizes do **not** shrink to fit the small screen. Legibility in a
  warehouse beats density; buy space back from padding instead.
- Motion is short. At 300 scans a shift, animation is felt as lag.

## After changing anything

Check both themes and a realistic screen width. A contrast regression in dark
mode is invisible until someone is on a night shift.
