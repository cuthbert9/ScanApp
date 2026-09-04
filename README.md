# scanapp

Dock loading app for **Zebra MC9450** rugged handhelds — warehouse dispatch,
scanning, load reconciliation and offline sync.

- Working rules for humans and AI: [CLAUDE.md](CLAUDE.md)
- How the code is laid out: [ARCHITECTURE.md](ARCHITECTURE.md)

## Running it

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # required
flutter run
```

Generated files (`*.g.dart`, `*.freezed.dart`) are git-ignored, so a fresh clone
does not compile until codegen has run.

```bash
dart format . && flutter analyze
flutter test
```

## Data layer — interfaces and swap points

The app runs entirely on an in-memory mock. **No HTTP client, no API keys, no
backend configuration exists anywhere in the tree**, by design.

Every screen talks to an interface in `lib/domain/repositories/`, never to a
concrete class. One implementation exists per interface, all backed by a single
store — `lib/data/mock_backend.dart` — which holds the seed state and all the
business rules.

| Interface | Mock implementation | What the real one will do |
|---|---|---|
| `OrderRepository` | `MockOrderRepository` | `GET /bays/{bay}/orders`, `GET /orders/{docNo}` |
| `ScanRepository` | `MockScanRepository` | Receive decoded barcodes from the DataWedge intent bridge; `POST /orders/{docNo}/scans`. **The rule ladder stays server-side or in the repository — never in a widget.** |
| `LoadRepository` | `MockLoadRepository` | `POST /orders/{docNo}/seal`, returning the amended manifest number |
| `SyncRepository` | `MockSyncRepository` | Persist to an encrypted local store; push batches to the ERP |
| `StationRepository` | `MockStationRepository` | Read the station from managed configuration; pull bays and routes from dispatch |
| `OfficerRepository` | `MockOfficerRepository` | Read the officer from the session; figures from the productivity endpoint |
| `SettingsRepository` | `MockSettingsRepository` | **Never becomes HTTP** — device-local preferences. Swap the in-memory map for `shared_preferences`. |

### The exact swap points

Each repository is provided in exactly one place. Change the returned
implementation and nothing above it moves — no widget, no controller, no test
that overrides the provider.

```dart
// lib/data/repository_providers.dart   (added in phase 2)
@Riverpod(keepAlive: true)
OrderRepository orderRepository(Ref ref) =>
    MockOrderRepository(ref.watch(mockBackendProvider));   // ← swap here
```

Tests override the same providers, so a fixture never has to reach past the
interface either.

### Editing the demo scenario

**`lib/data/mock_seed.dart` holds every seed value in the app** — the officer,
the station list, all three orders and their lines, the cold-chain logger, the
sync queue and the shift figures. Nothing else in the codebase contains a
literal figure.

Numbers that look hardcoded on screen are computed:

| Shown | Derived from |
|---|---|
| `13/14`, `92.9 %`, `1 short` | `Order.lines` and their `state` |
| `2 986 kg` / `18.4 m³` | summed over the **verified** lines only |
| `3 orders · 41 units · 2 cold chain` | the staged order list |
| `99.3 %` first pass | `(unitsScanned - coldChainHolds) / unitsScanned` |
| the amber header dot and the Sync tab badge | one `pendingSyncCount` |

Change one line's `state` in the seed and every one of those moves together.

### Debug affordances

Compiled out of release builds:

- **Simulate scan** — stands in for a hardware trigger pull.
- **Type an SSCC** — reproduce duplicate, wrong-order and FEFO outcomes
  deliberately.
- **Simulate offline** — watch scans queue up instead of flushing.
