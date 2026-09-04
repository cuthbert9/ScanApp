import 'dart:math';

import '../domain/models/cold_chain_log.dart';
import '../domain/models/display_choice.dart';
import '../domain/models/load_seal.dart';
import '../domain/models/officer.dart';
import '../domain/models/order.dart';
import '../domain/models/order_line.dart';
import '../domain/models/scan_event.dart';
import '../domain/models/shift_stats.dart';
import '../domain/models/station.dart';
import '../domain/models/sync_mode.dart';
import '../domain/models/sync_record.dart';
import '../domain/models/sync_status.dart';
import '../domain/models/vehicle.dart';
import 'mock_seed.dart';

/// The single in-memory source of truth behind every `Mock*` repository.
///
/// One store, not seven: the Orders, Scan and Load screens read the *same*
/// [Order] objects, which is what makes "change one line and every number moves
/// together" true rather than aspirational.
///
/// All the business rules live here — the scan ladder, FEFO, sealing, flushing.
/// Repositories are thin adapters that add latency and wrap results; widgets
/// hold none of it.
class MockBackend {
  MockBackend() {
    reset();
  }

  late List<Order> _orders;
  late Map<String, List<ScanEvent>> _feeds;
  late Map<String, ColdChainLog> _coldChain;
  late Map<String, LoadSeal> _seals;
  late List<SyncRecord> _syncRecords;
  late SyncMode _syncMode;
  late DateTime? _lastPushAt;
  late bool _lastPushAccepted;
  late bool _simulateOffline;
  late Station _station;
  late List<Station> _stations;
  late ThemeChoice _themeChoice;
  late TextScaleChoice _textScale;

  final Random _random = Random(20260904);
  int _syncSeq = 0;

  /// Restores the seed. Used by tests so each gets a clean scenario.
  void reset() {
    _orders = MockSeed.orders();
    _feeds = <String, List<ScanEvent>>{};
    _coldChain = <String, ColdChainLog>{
      'DO-2026-04417': MockSeed.coldChain04417,
    };
    _seals = <String, LoadSeal>{};
    _syncRecords = MockSeed.syncRecords();
    _syncMode = MockSeed.syncMode;
    _lastPushAt = MockSeed.lastPushAt;
    _lastPushAccepted = true;
    _simulateOffline = false;
    _station = MockSeed.station;
    _stations = MockSeed.stations;
    _themeChoice = ThemeChoice.auto;
    _textScale = TextScaleChoice.standard;
    _syncSeq = _syncRecords.length;

    // The seeded feed shows the held line at the top, as the design does.
    final Order first = _orders.first;
    final OrderLine? held = first.lines
        .where((OrderLine l) => l.isHeld)
        .firstOrNull;
    if (held != null) {
      _feeds[first.docNo] = <ScanEvent>[
        ScanEvent(
          seq: 1,
          at: MockSeed.at(8, 41),
          line: held,
          result: ScanResult.hold,
          reason: fefoReason,
          rawCode: held.sscc,
        ),
      ];
    }
  }

  static const String fefoReason = 'FEFO: earlier lot in stock';

  // ----------------------------------------------------------------- reads
  Officer get officer => MockSeed.officer;
  ShiftStats get shiftStats => MockSeed.shiftStats;
  Station get station => _station;
  List<Station> get stations => List<Station>.unmodifiable(_stations);
  ThemeChoice get themeChoice => _themeChoice;
  TextScaleChoice get textScale => _textScale;

  /// Sealed orders leave the staged queue.
  List<Order> stagedOrders(String bay) => _orders
      .where((Order o) => o.bay == bay && !o.status.isSealed)
      .toList(growable: false);

  Order? orderByDocNo(String docNo) =>
      _orders.where((Order o) => o.docNo == docNo).firstOrNull;

  List<ScanEvent> feed(String docNo) =>
      List<ScanEvent>.unmodifiable(_feeds[docNo] ?? const <ScanEvent>[]);

  ColdChainLog? coldChain(String docNo) => _coldChain[docNo];

  LoadSeal? sealFor(String docNo) => _seals[docNo];

  SyncStatus get syncStatus => SyncStatus(
    mode: _syncMode,
    records: List<SyncRecord>.unmodifiable(_syncRecords),
    tripReference: MockSeed.tripReference,
    hub: MockSeed.hub,
    lastPushAt: _lastPushAt,
    lastPushAccepted: _lastPushAccepted,
    simulateOffline: _simulateOffline,
  );

  // -------------------------------------------------------------- scanning
  /// Stands in for a hardware trigger pull.
  ///
  /// Presents the next pending line. When every line has been dealt with — the
  /// seeded state of DO-2026-04417, which is 13 verified and 1 held — it
  /// re-presents the held line, which is what an operator does when they try a
  /// held unit again. The rules then run exactly as they would on a real pull.
  ScanEvent simulateScan(String docNo) {
    final Order? order = orderByDocNo(docNo);
    if (order == null) {
      return _record(docNo, null, ScanResult.wrongOrder, 'Unknown order', '');
    }
    final OrderLine? next =
        order.nextPendingLine ??
        order.lines.where((OrderLine l) => l.isHeld).firstOrNull;
    if (next == null) {
      return _record(
        docNo,
        null,
        ScanResult.duplicate,
        'Every line on this order is already verified',
        '',
      );
    }
    return scanCode(docNo, next.sscc);
  }

  /// The rule ladder, most specific first.
  ///
  /// Order matters: "you already scanned this" is more useful than "wrong
  /// order", and both are more useful than a FEFO hold.
  ScanEvent scanCode(String docNo, String rawCode) {
    final String sscc = _normalise(rawCode);
    final Order? order = orderByDocNo(docNo);

    if (order == null) {
      return _record(
        docNo,
        null,
        ScanResult.wrongOrder,
        'Unknown order',
        rawCode,
      );
    }
    if (!order.status.acceptsScans) {
      return _record(
        docNo,
        null,
        ScanResult.duplicate,
        'This load is sealed and takes no further scans',
        rawCode,
      );
    }

    // (a) already scanned in this session
    final bool seen = (_feeds[docNo] ?? const <ScanEvent>[]).any(
      (ScanEvent e) => e.line?.sscc == sscc && e.result != ScanResult.duplicate,
    );
    final OrderLine? line = order.lineBySscc(sscc);
    if (seen && line != null) {
      return _record(
        docNo,
        line,
        ScanResult.duplicate,
        'Duplicate — already scanned on this load',
        rawCode,
      );
    }

    // (b) belongs to another order
    if (line == null) {
      final Order? owner = _orders
          .where((Order o) => o.docNo != docNo && o.lineBySscc(sscc) != null)
          .firstOrNull;
      if (owner != null) {
        return _record(
          docNo,
          owner.lineBySscc(sscc),
          ScanResult.wrongOrder,
          'Belongs to ${owner.docNo}',
          rawCode,
        );
      }
      return _record(
        docNo,
        null,
        ScanResult.wrongOrder,
        'Not on this manifest',
        rawCode,
      );
    }

    // (c) an earlier-expiring lot of the same product is still in stock
    if (_hasEarlierLotInStock(line)) {
      _setLineState(docNo, line.seq, LineState.held, holdReason: 'FEFO hold');
      return _record(docNo, line, ScanResult.hold, fefoReason, rawCode);
    }

    // (d) accepted
    _setLineState(docNo, line.seq, LineState.verified);
    return _record(docNo, line, ScanResult.ok, null, rawCode);
  }

  bool _hasEarlierLotInStock(OrderLine line) {
    final List<DateTime>? stock = MockSeed.fefoStock[line.productName];
    if (stock == null) return false;
    return stock.any((DateTime d) => d.isBefore(line.expiry));
  }

  /// Strips GS1 bracket notation so a typed `(00)3600…` matches a bare SSCC.
  String _normalise(String raw) {
    final String trimmed = raw.trim();
    final RegExpMatch? m = RegExp(r'\(00\)(\d+)').firstMatch(trimmed);
    if (m != null) return m.group(1)!;
    return trimmed.replaceAll(RegExp(r'[^0-9]'), '').isEmpty
        ? trimmed
        : trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  }

  void _setLineState(
    String docNo,
    int seq,
    LineState state, {
    String? holdReason,
  }) {
    _updateOrder(docNo, (Order o) {
      final List<OrderLine> next = o.lines
          .map(
            (OrderLine l) => l.seq == seq
                ? l.copyWith(state: state, holdReason: holdReason)
                : l,
          )
          .toList(growable: false);
      return o.copyWith(lines: next);
    });
  }

  ScanEvent _record(
    String docNo,
    OrderLine? line,
    ScanResult result,
    String? reason,
    String rawCode,
  ) {
    final List<ScanEvent> feed = _feeds.putIfAbsent(docNo, () => <ScanEvent>[]);
    final ScanEvent event = ScanEvent(
      seq: feed.length + 1,
      at: DateTime.now(),
      line: line,
      result: result,
      reason: reason,
      rawCode: rawCode,
    );
    // Newest first.
    feed.insert(0, event);

    // Every outcome is work to report, including a rejection.
    _enqueueSync('scan');
    return event;
  }

  // ------------------------------------------------------------ cold chain
  /// Advances the door timer and drifts the temperature.
  ///
  /// A reading outside 2–8 °C sets an excursion on both the log and the order,
  /// and an excursion blocks sealing. It is never cleared: a consignment that
  /// went out of band stays suspect.
  ColdChainLog tickColdChain(String docNo, int elapsedSeconds) {
    final ColdChainLog current =
        _coldChain[docNo] ??
        ColdChainLog(
          loggerId: 'MSD-LG-0000',
          tempC: 4.5,
          doorOpenSeconds: 0,
          stable: true,
        );

    // Drift by up to ±0.3 °C a tick, held inside a realistic 3.4–6.4 band so a
    // demo does not trip an excursion by accident.
    final double drift = (_random.nextDouble() - 0.5) * 0.6;
    final double next = (current.tempC + drift).clamp(3.4, 6.4);

    final ColdChainLog updated = current.copyWith(
      tempC: double.parse(next.toStringAsFixed(1)),
      doorOpenSeconds: current.doorOpenSeconds + elapsedSeconds,
      stable: next >= Vehicle.minSafeTempC && next <= Vehicle.maxSafeTempC,
      hadExcursion:
          current.hadExcursion ||
          next < Vehicle.minSafeTempC ||
          next > Vehicle.maxSafeTempC,
    );
    _coldChain[docNo] = updated;

    if (updated.hadExcursion) {
      _updateOrder(docNo, (Order o) => o.copyWith(hasColdChainExcursion: true));
    }
    // Keep the vehicle's reading in step, so the reconciliation meter agrees.
    _updateOrder(
      docNo,
      (Order o) => o.copyWith(
        vehicle: o.vehicle.copyWith(
          reeferTempC: updated.tempC,
          reeferStable: updated.stable,
        ),
      ),
    );
    return updated;
  }

  // --------------------------------------------------------------- sealing
  /// Seals a load, or throws a reason it cannot be sealed.
  LoadSeal seal(String docNo) {
    final Order? order = orderByDocNo(docNo);
    if (order == null) throw StateError('Unknown order $docNo');
    if (order.status.isSealed) throw StateError('$docNo is already sealed');
    if (order.hasColdChainExcursion) {
      throw StateError(
        'Cold-chain excursion recorded — this load cannot be sealed until a '
        'supervisor clears it.',
      );
    }

    final LoadSeal seal = LoadSeal(
      docNo: docNo,
      sealedAt: DateTime.now(),
      orderedUnits: order.units,
      verifiedUnits: order.verifiedUnits,
      shortUnits: order.shortUnits,
      overUnits: order.overUnits,
      amended: order.shortUnits > 0 || order.overUnits > 0,
    );
    _seals[docNo] = seal;
    _updateOrder(docNo, (Order o) => o.copyWith(status: OrderStatus.sealed));
    _enqueueSync('seal');
    return seal;
  }

  // ------------------------------------------------------------------ sync
  void _enqueueSync(String type) {
    _syncSeq++;
    _syncRecords = <SyncRecord>[
      ..._syncRecords,
      SyncRecord(
        id: 'Q-${_syncSeq.toString().padLeft(4, '0')}',
        type: type,
        createdAt: DateTime.now(),
        payloadBytes: 1800 + _random.nextInt(600),
      ),
    ];
  }

  SyncStatus setSyncMode(SyncMode mode) {
    _syncMode = mode;
    return syncStatus;
  }

  SyncStatus setSimulatedOffline(bool value) {
    _simulateOffline = value;
    return syncStatus;
  }

  /// Marks everything pending as sent. The caller supplies the delay.
  SyncStatus flush() {
    _syncRecords = _syncRecords
        .map(
          (SyncRecord r) =>
              r.isPending ? r.copyWith(state: SyncRecordState.sent) : r,
        )
        .toList(growable: false);
    _lastPushAt = DateTime.now();
    _lastPushAccepted = true;
    return syncStatus;
  }

  // -------------------------------------------------------------- stations
  Station selectStation(String code) {
    final Station? found = _stations
        .where((Station s) => s.code == code)
        .firstOrNull;
    if (found == null) throw StateError('Unknown station $code');
    // Re-syncing stamps a fresh time and puts the device inside the fence.
    _station = found.copyWith(
      mapSyncedAt: DateTime.now(),
      insideGeofence: true,
    );
    _stations = _stations
        .map((Station s) => s.code == code ? _station : s)
        .toList(growable: false);
    return _station;
  }

  // ----------------------------------------------------------- preferences
  void setThemeChoice(ThemeChoice choice) => _themeChoice = choice;
  void setTextScale(TextScaleChoice choice) => _textScale = choice;

  // ----------------------------------------------------------------- utils
  void _updateOrder(String docNo, Order Function(Order) change) {
    _orders = _orders
        .map((Order o) => o.docNo == docNo ? change(o) : o)
        .toList(growable: false);
  }
}
