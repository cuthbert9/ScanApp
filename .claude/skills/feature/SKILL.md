---
name: feature
description: Scaffold or extend a feature slice in lib/features/ with the project's four-folder structure, Riverpod controllers, repository interface and fake implementation. Use when adding a new screen, flow, or capability to scanapp.
---

# Add or extend a feature

> `lib/features/` does not exist yet. The first run of this skill creates it,
> along with whatever `lib/core/` pieces the feature needs (`Result`,
> `AppException`) at the paths CLAUDE.md specifies.

Follow this in order. Do not skip step 1 — it is the step that prevents
duplicate code, which is the whole reason this skill exists.

## 1. Survey before you build

```bash
ls lib/features/                                   # what already exists
rg -n "class .*Repository" lib/features/ lib/core/ # existing data access
rg -l "<domain noun>" lib/                         # has this concept a home?
```

Decide explicitly, and say which you chose:

- The capability belongs in an **existing feature** → extend it. Prefer this.
- It is genuinely a new bounded slice → create it.
- It is cross-cutting (used by 2+ features) → it belongs in `lib/shared/` or
  `lib/core/`, not in a feature at all.

Two features that both "own" the same noun is a design error. Resolve it now.

## 2. Create only the folders you will actually fill

```
lib/features/<feature>/
  domain/        <noun>.dart                 @freezed model, pure Dart
                 <noun>_repository.dart      abstract interface
  data/          <noun>_repository_impl.dart implements the interface
                 fake_<noun>_repository.dart in-memory, for UI-first work
  application/   <noun>_controller.dart      @riverpod
  presentation/  <noun>_screen.dart
                 widgets/                    ONLY if 2+ widgets are local
```

An empty folder is noise. Add each one when it earns its place.

## 3. Domain first — it has no dependencies

The model is `@freezed`, pure Dart, no Flutter import. The repository is an
`abstract interface class` returning `Result<T>`:

```dart
abstract interface class ItemRepository {
  Future<Result<Item>> byBarcode(String barcode);
}
```

The interface lives in `domain/`, the implementation in `data/`. That direction
is what lets the backend land later without touching the UI.

## 4. Data — fake first

The backend is a separate MSSQL-backed repo that this app only calls. Until an
endpoint exists, write `Fake<Noun>Repository` returning realistic in-memory
data, including at least one failure case so error states get built too.

Every caught transport error becomes a specific `AppException` subclass here.
Never let a `DioException` or `PlatformException` escape `data/`.

## 5. Application — Riverpod, no widgets

```dart
@riverpod
class ItemController extends _$ItemController {
  @override
  FutureOr<Item?> build() => null;
  ...
}
```

The repository provider is overridden at the root to select fake vs real. That
override is the ONLY place that knows which backend is live.

## 6. Presentation — composition only

Build from `lib/shared/widgets/`. If a needed widget does not exist, stop and
run `/ui-component` rather than inlining a bespoke one.

Read every visual value from `context.*` tokens — the design-token hook will
reject literals. Remember the device: 56 dp targets for primary actions, no
flow that requires an on-screen tap to scan, and every action key-reachable.

Make the screen scrollable from the start. Retrofitting scrolling after a
layout is built is far more work than starting with `ListView` /
`SingleChildScrollView`, and in landscape (320 dp of height) or with the
keyboard open (~280 dp) almost every screen needs it (CLAUDE.md rule 1c).

## 7. Wire and verify

Add the route to the router. Then:

```bash
dart run build_runner build --delete-conflicting-outputs
dart format . && flutter analyze
```

Then check the screen in portrait (320×533), landscape (533×320), with the
keyboard open, and at font scale 1.3. An overflow found now is a two-minute
fix; found on a device in a warehouse it is a support ticket.

## 8. Close the loop

Update `ARCHITECTURE.md` with the new feature and its responsibility — or run
`/docs-sync`. The Stop hook will remind you, but doing it here is cheaper.
