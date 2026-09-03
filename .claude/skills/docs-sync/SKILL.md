---
name: docs-sync
description: Create or refresh ARCHITECTURE.md so it matches the code as it is now. Use after adding a feature, dependency or convention, or when the repo sentinel reports documentation drift.
---

# Sync the living documentation

`ARCHITECTURE.md` is the file a new developer — or a future session with no
context — reads first. Its only job is to let someone find their way around
without opening every file.

A stale architecture doc is worse than none, because it is trusted. So this is
a **rewrite from observation**, never a patch from memory.

## 1. Observe the code as it actually is

```bash
find lib -type d -not -path '*/.*' | sort
ls lib/features/
rg -n "^  [a-z_]+:" pubspec.yaml | head -40        # real dependencies
rg -n "GoRoute\(" lib/ -A2                         # real routes
rg -n "abstract interface class" lib/              # real seams
```

Do not describe anything you have not just verified exists.

## 2. Write these sections, in this order

1. **What the app is** — one paragraph. The MC9450 constraints belong here,
   because they explain almost every other decision.
2. **How to run it** — the exact commands, including
   `dart run build_runner build --delete-conflicting-outputs`, and the fact
   that a fresh clone will not compile until codegen runs.
3. **Directory map** — a tree with one line per directory saying what belongs
   there. This is the highest-value section; spend the most effort here.
4. **Dependency rule** — `features/ → shared/ → core/`, one direction, and no
   feature imports another.
5. **Design system** — the three layers, and the `context.*` accessors. Point
   at `.claude/skills/design-token/SKILL.md` rather than restating it.
6. **Feature inventory** — a table: feature, what it owns, its entry screen.
   Keep this current; it is the fastest orientation tool in the file.
7. **Data & errors** — `Result<T>`, `AppException`, where transport errors get
   translated, and the fake-vs-real repository override.
8. **Scanner** — that scanning is DataWedge intent broadcasts, the
   `ScannerService` seam, and that a mock backs desktop development.
9. **Decisions** — a short table of choices a newcomer would otherwise
   re-litigate: why Riverpod, why generated files are ignored, why
   `riverpod_lint` is absent, why DataWedge is wired natively. One line of
   reasoning each.

## 3. Rules for the writing

- **Describe, do not aspire.** If a folder is empty, say it is planned, or omit
  it. A doc that describes intentions reads as a doc that describes reality.
- **Link, do not duplicate.** Rules live in `CLAUDE.md`; point at it. Anything
  written twice will disagree within a month.
- **Explain the non-obvious.** Skip what the code already says. Spend the words
  on *why* — why fakes before the real backend, why 12 dp gutters, why tokens.
- **Date nothing.** "As of March" ages badly. Describe the current state.

## 4. Verify before finishing

Re-read it as someone who has never seen the repo:

- Could they run the app?
- Could they find where a given screen lives?
- Could they add a screen without inventing a new convention?

If any answer is no, that section needs work.
