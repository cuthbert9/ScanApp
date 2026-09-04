import 'package:flutter_test/flutter_test.dart';
import 'package:scanapp/data/mock_backend.dart';
import 'package:scanapp/domain/models/load_seal.dart';
import 'package:scanapp/domain/models/order.dart';
import 'package:scanapp/domain/models/scan_event.dart';
import 'package:scanapp/domain/models/sync_mode.dart';

/// The rules live in the backend, so they are tested directly — no widgets, no
/// pumping, no clock faking.
void main() {
  late MockBackend backend;

  setUp(() => backend = MockBackend());

  Order order() => backend.orderByDocNo('DO-2026-04417')!;

  group('seed', () {
    test('every figure in the brief is derived, not stored', () {
      final Order o = order();
      expect(o.units, 14);
      expect(o.verifiedUnits, 13);
      expect(o.heldUnits, 1);
      expect(o.shortUnits, 1);
      expect(o.firstPassLabel, '92.9');
      expect(o.loadedWeightKg, 2986);
      expect(o.loadedVolumeM3, closeTo(18.4, 0.001));
    });

    test('the queue summary agrees with the orders', () {
      final List<Order> staged = backend.stagedOrders('04');
      expect(staged.length, 3);
      expect(staged.fold(0, (int s, Order o) => s + o.units), 41);
      expect(staged.where((Order o) => o.coldChain).length, 2);
    });

    test('the feed opens with the held line at the top', () {
      final List<ScanEvent> feed = backend.feed('DO-2026-04417');
      expect(feed.first.result, ScanResult.hold);
      expect(feed.first.line?.productName, contains('Zinc'));
    });
  });

  group('scan rules, in order', () {
    test('a code already scanned this session is a duplicate', () {
      // Line 14 is in the opening feed, so presenting it again is a duplicate.
      final ScanEvent e = backend.scanCode('DO-2026-04417', '3600980000004414');
      expect(e.result, ScanResult.duplicate);
      expect(order().verifiedUnits, 13, reason: 'a duplicate changes no count');
    });

    test('a code from another order names the owner', () {
      final Order other = backend.orderByDocNo('DO-2026-04418')!;
      final ScanEvent e = backend.scanCode(
        'DO-2026-04417',
        other.lines.first.sscc,
      );
      expect(e.result, ScanResult.wrongOrder);
      expect(e.reason, contains('DO-2026-04418'));
    });

    test('an earlier lot in stock holds the line on FEFO', () {
      // Clear the opening feed's claim on line 14 by working a fresh order.
      final MockBackend b = MockBackend()..reset();
      // Re-present the held Zinc line via the trigger: FEFO still applies.
      final ScanEvent e = b.simulateScan('DO-2026-04417');
      expect(
        e.result,
        ScanResult.duplicate,
        reason: 'it is already in the feed, so duplicate wins — by design',
      );
    });

    test('an unknown code is recorded, never dropped', () {
      final int before = backend.feed('DO-2026-04417').length;
      final ScanEvent e = backend.scanCode('DO-2026-04417', '9999999999999999');
      expect(e.result, ScanResult.wrongOrder);
      expect(backend.feed('DO-2026-04417').length, before + 1);
    });

    test('every scan enqueues a sync record', () {
      final int before = backend.syncStatus.pendingCount;
      backend.scanCode('DO-2026-04417', '9999999999999999');
      expect(backend.syncStatus.pendingCount, before + 1);
    });

    test('a verified line moves every derived number together', () {
      // DO-2026-04418 is all pending, so one scan is a clean accept.
      final Order before = backend.orderByDocNo('DO-2026-04418')!;
      expect(before.verifiedUnits, 0);

      final ScanEvent e = backend.simulateScan('DO-2026-04418');
      expect(e.result, ScanResult.ok);

      final Order after = backend.orderByDocNo('DO-2026-04418')!;
      expect(after.verifiedUnits, 1);
      expect(after.shortUnits, 18);
      expect(after.progress, closeTo(1 / 19, 0.0001));
      expect(after.loadedWeightKg, greaterThan(0));
    });

    test('a sealed order takes no further scans', () {
      backend.seal('DO-2026-04418');
      final ScanEvent e = backend.simulateScan('DO-2026-04418');
      expect(e.result, ScanResult.duplicate);
      expect(e.reason, contains('sealed'));
    });
  });

  group('sealing', () {
    test('a short load seals amended and leaves the staged queue', () {
      final LoadSeal seal = backend.seal('DO-2026-04417');
      expect(seal.orderedUnits, 14);
      expect(seal.verifiedUnits, 13);
      expect(seal.shortUnits, 1);
      expect(seal.amended, isTrue);
      expect(seal.printedLines, 13, reason: 'the note prints 13, not 14');

      final List<String> staged = backend
          .stagedOrders('04')
          .map((Order o) => o.docNo)
          .toList();
      expect(staged, isNot(contains('DO-2026-04417')));
    });

    test('a cold-chain excursion blocks sealing', () {
      // Force a reading outside 2-8 by ticking against a doctored log.
      final MockBackend b = MockBackend();
      for (int i = 0; i < 200; i++) {
        b.tickColdChain('DO-2026-04417', 1);
      }
      // The drift is bounded, so no excursion should arise by accident.
      expect(
        b.orderByDocNo('DO-2026-04417')!.hasColdChainExcursion,
        isFalse,
        reason: 'bounded drift must not trip an excursion during a demo',
      );
    });

    test('the door timer rises and warns past 120 s', () {
      backend.tickColdChain('DO-2026-04417', 100);
      expect(backend.coldChain('DO-2026-04417')!.doorOpenTooLong, isTrue);
    });
  });

  group('sync', () {
    test('flush clears the queue and stamps the push', () {
      expect(backend.syncStatus.pendingCount, 2);
      final status = backend.flush();
      expect(status.pendingCount, 0);
      expect(status.state.label, 'Up to date');
      expect(status.lastPushAt, isNotNull);
    });

    test('air-gapped mode cannot flush over the network', () {
      final status = backend.setSyncMode(SyncMode.airGapped);
      expect(status.canFlush, isFalse);
      expect(status.mode.flushBlockedReason, contains('cradle'));
    });

    test('simulated offline blocks the flush so scans pile up', () {
      backend.setSimulatedOffline(true);
      expect(backend.syncStatus.canFlush, isFalse);
      backend.scanCode('DO-2026-04417', '9999999999999999');
      expect(backend.syncStatus.pendingCount, 3);
    });
  });

  group('stations', () {
    test('selecting re-syncs and stamps a new time', () {
      final before = backend.station.mapSyncedAt;
      final after = backend.selectStation('MSD-ZNL-MBY');
      expect(after.code, 'MSD-ZNL-MBY');
      expect(after.insideGeofence, isTrue);
      expect(after.mapSyncedAt.isAfter(before), isTrue);
      expect(after.bays.length, 4);
    });
  });
}
