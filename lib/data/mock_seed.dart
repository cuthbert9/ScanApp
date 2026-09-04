import '../domain/models/cold_chain_log.dart';
import '../domain/models/officer.dart';
import '../domain/models/order.dart';
import '../domain/models/order_line.dart';
import '../domain/models/shift_stats.dart';
import '../domain/models/station.dart';
import '../domain/models/sync_mode.dart';
import '../domain/models/sync_record.dart';
import '../domain/models/vehicle.dart';

/// **Every seed value in the app, in one place.**
///
/// Edit this file to change the demo scenario — nothing else reads a literal.
/// [MockBackend] copies these into mutable state on construction, so the
/// originals here are never modified at runtime.
abstract final class MockSeed {
  /// The day the whole scenario is set on. Fixed rather than `DateTime.now()`
  /// so the demo and the tests are reproducible.
  static final DateTime day = DateTime(2026, 9, 4);

  static DateTime at(int hour, int minute) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  // ---------------------------------------------------------------- officer
  static final Officer officer = Officer(
    id: 'OP-2214',
    name: 'Neema Mwakalinga',
    staffNo: 'MSD-OP-2214',
    grade: 'Loading Officer II',
    shiftStart: at(6, 0),
    shiftEnd: at(15, 0),
  );

  /// Taken at 12:12 against a 06:00 start, which is what shows `6:12 ON SHIFT`.
  static final DateTime capturedAt = at(12, 12);

  static final ShiftStats shiftStats = ShiftStats(
    unitsScanned: 148,
    coldChainHolds: 1,
    medianSecondsPerUnit: 11,
    loadsSealed: 3,
    week: <DailyScanCount>[
      const DailyScanCount(label: 'T', dayName: 'Thursday', units: 121),
      const DailyScanCount(label: 'F', dayName: 'Friday', units: 96),
      const DailyScanCount(label: 'S', dayName: 'Saturday', units: 44),
      const DailyScanCount(
        label: 'S',
        dayName: 'Sunday',
        units: 0,
        closed: true,
      ),
      const DailyScanCount(label: 'M', dayName: 'Monday', units: 138),
      const DailyScanCount(label: 'T', dayName: 'Tuesday', units: 152),
      const DailyScanCount(
        label: 'W',
        dayName: 'Wednesday',
        units: 148,
        isToday: true,
      ),
    ],
  );

  // --------------------------------------------------------------- stations
  static final Station station = Station(
    code: 'MSD-CVS-DAR',
    name: 'Dar es Salaam Central Vaccine Store',
    lat: -6.8123,
    lng: 39.2691,
    assignedBay: '04',
    bays: const <String>['01', '02', '03', '04', '05', '06'],
    geofenceMetres: 40,
    insideGeofence: true,
    mapSyncedAt: at(7, 58),
  );

  /// Offered by the `Change station` picker.
  static final List<Station> stations = <Station>[
    station,
    Station(
      code: 'MSD-ZNL-DOM',
      name: 'Dodoma Zonal Store',
      lat: -6.1630,
      lng: 35.7516,
      assignedBay: '02',
      bays: const <String>['01', '02', '03'],
      geofenceMetres: 60,
      insideGeofence: false,
      mapSyncedAt: at(7, 58),
    ),
    Station(
      code: 'MSD-ZNL-MBY',
      name: 'Mbeya Zonal Store',
      lat: -8.9094,
      lng: 33.4608,
      assignedBay: '01',
      bays: const <String>['01', '02', '03', '04'],
      geofenceMetres: 45,
      insideGeofence: false,
      mapSyncedAt: at(7, 58),
    ),
  ];

  // ----------------------------------------------------------------- orders
  static const Vehicle _truck04417 = Vehicle(
    plate: 'T 421 DKV',
    maxWeightKg: 8000,
    maxVolumeM3: 26,
    reeferTempC: 4.3,
  );
  static const Vehicle _truck04418 = Vehicle(
    plate: 'T 118 CQA',
    maxWeightKg: 8000,
    maxVolumeM3: 26,
  );
  static const Vehicle _truck04421 = Vehicle(
    plate: 'T 906 BLE',
    maxWeightKg: 3500,
    maxVolumeM3: 12,
    reeferTempC: 5.1,
  );

  /// SSCCs run so that line #10 is `3600980000004401`, as specified. Line #14
  /// is deliberately out of that run at `...4414`.
  static String _sscc(int seq) =>
      '36009800000044${(1 + seq - 10).toString().padLeft(2, '0')}';

  /// The 14 lines of DO-2026-04417: 13 verified, 1 held.
  ///
  /// Weights and volumes across the 13 verified lines sum to exactly
  /// **2 986 kg** and **18.4 m³**, which is what the utilisation meters show.
  static List<OrderLine> lines04417() {
    // Lines 1-9: three each of RUTF, Oxytocin and Amoxicillin.
    const List<List<Object>> filler = <List<Object>>[
      <Object>['RUTF Sachets 92 g', 150, 310.0, 1.8, 'RTF25A', 2028, 11],
      <Object>['Oxytocin 10 IU', 100, 180.0, 1.1, 'OXY25B', 2027, 8],
      <Object>['Amoxicillin 250 mg Caps', 1000, 239.0, 1.5, 'AMX25D', 2027, 6],
    ];

    final List<OrderLine> lines = <OrderLine>[];
    for (int seq = 1; seq <= 9; seq++) {
      final List<Object> p = filler[(seq - 1) % filler.length];
      lines.add(
        OrderLine(
          seq: seq,
          productName: '${p[0]} ×${p[1]}',
          quantity: p[1] as int,
          sscc: _sscc(seq),
          lot: '${p[4]}${seq.toString().padLeft(3, '0')}',
          expiry: DateTime(p[5] as int, p[6] as int),
          weightKg: p[2] as double,
          volumeM3: p[3] as double,
          state: LineState.verified,
        ),
      );
    }

    lines.addAll(<OrderLine>[
      OrderLine(
        seq: 10,
        productName: 'Amoxicillin 250 mg Caps ×1000',
        quantity: 1000,
        sscc: '3600980000004401',
        lot: 'AMX25C441',
        expiry: DateTime(2027, 6),
        weightKg: 239,
        volumeM3: 1.5,
        state: LineState.verified,
      ),
      OrderLine(
        seq: 11,
        productName: 'ORS Sachets 20.5 g ×500',
        quantity: 500,
        sscc: '3600980000004402',
        lot: 'ORS24H902',
        expiry: DateTime(2028, 1),
        weightKg: 205,
        volumeM3: 1.2,
        state: LineState.verified,
      ),
      OrderLine(
        seq: 12,
        productName: 'Paracetamol 500 mg ×1000',
        quantity: 1000,
        sscc: '3600980000004403',
        lot: 'PCM25A006',
        expiry: DateTime(2028, 4),
        weightKg: 260,
        volumeM3: 1.6,
        state: LineState.verified,
      ),
      OrderLine(
        seq: 13,
        productName: 'mRDT Malaria Test ×25',
        quantity: 25,
        sscc: '3600980000004404',
        lot: 'MRD24L221',
        expiry: DateTime(2027, 9),
        weightKg: 95,
        volumeM3: 0.9,
        state: LineState.verified,
      ),
      // Held on FEFO: an earlier Zinc lot is still in stock. See [fefoStock].
      OrderLine(
        seq: 14,
        productName: 'Zinc Sulfate 20 mg ×500',
        quantity: 500,
        sscc: '3600980000004414',
        lot: 'ZNC26B118',
        expiry: DateTime(2029, 2),
        weightKg: 214,
        volumeM3: 1.3,
        state: LineState.held,
        holdReason: 'FEFO hold',
      ),
    ]);
    return lines;
  }

  /// Plain pending lines, for the orders that have not started loading.
  static List<OrderLine> pendingLines({
    required int count,
    required int ssccFrom,
    required String lotPrefix,
  }) {
    const List<List<Object>> catalogue = <List<Object>>[
      <Object>['Paracetamol 500 mg', 1000, 260.0, 1.6],
      <Object>['ORS Sachets 20.5 g', 500, 205.0, 1.2],
      <Object>['Amoxicillin 250 mg Caps', 1000, 239.0, 1.5],
      <Object>['mRDT Malaria Test', 25, 95.0, 0.9],
      <Object>['Zinc Sulfate 20 mg', 500, 214.0, 1.3],
    ];
    return List<OrderLine>.generate(count, (int i) {
      final List<Object> p = catalogue[i % catalogue.length];
      return OrderLine(
        seq: i + 1,
        productName: '${p[0]} ×${p[1]}',
        quantity: p[1] as int,
        sscc: (ssccFrom + i).toString(),
        lot: '$lotPrefix${(i + 1).toString().padLeft(3, '0')}',
        expiry: DateTime(2028, 1 + (i % 12)),
        weightKg: p[2] as double,
        volumeM3: p[3] as double,
      );
    });
  }

  static List<Order> orders() => <Order>[
    Order(
      docNo: 'DO-2026-04417',
      consignee: 'Dodoma Zonal Store',
      routeCode: 'TZ-C-07',
      bay: '04',
      vehicle: _truck04417,
      status: OrderStatus.loading,
      coldChain: true,
      etd: at(9, 30),
      lines: lines04417(),
    ),
    Order(
      docNo: 'DO-2026-04418',
      consignee: 'Morogoro Regional Medical Store',
      routeCode: 'TZ-E-02',
      bay: '04',
      vehicle: _truck04418,
      status: OrderStatus.queued,
      etd: at(11, 0),
      lines: pendingLines(
        count: 19,
        ssccFrom: 3600980000004500,
        lotPrefix: 'MOR26',
      ),
    ),
    Order(
      docNo: 'DO-2026-04421',
      consignee: 'Ifakara District Hospital',
      routeCode: 'TZ-S-11',
      bay: '04',
      vehicle: _truck04421,
      status: OrderStatus.awaitingTruck,
      isEPI: true,
      coldChain: true,
      lines: pendingLines(
        count: 8,
        ssccFrom: 3600980000004600,
        lotPrefix: 'IFA26',
      ),
    ),
  ];

  // ------------------------------------------------------------- cold chain
  static const ColdChainLog coldChain04417 = ColdChainLog(
    loggerId: 'MSD-LG-2291',
    tempC: 4.3,
    doorOpenSeconds: 42,
    stable: true,
  );

  // ------------------------------------------------------------------ stock
  /// Lots still on the shelf, keyed by product name.
  ///
  /// A scan is held on FEFO when an **earlier-expiring** lot of the same
  /// product is still here. Only Zinc has one, which is why line #14 is held
  /// and nothing else is.
  static final Map<String, List<DateTime>> fefoStock = <String, List<DateTime>>{
    'Zinc Sulfate 20 mg ×500': <DateTime>[DateTime(2028, 5)],
  };

  // ------------------------------------------------------------------- sync
  static const SyncMode syncMode = SyncMode.storeAndForward;
  static const String tripReference = 'TSP FR 14.9';
  static const String hub = 'DAR CVS';
  static final DateTime lastPushAt = at(8, 9);

  static List<SyncRecord> syncRecords() => <SyncRecord>[
    SyncRecord(
      id: 'Q-0001',
      type: 'scan',
      createdAt: at(8, 7),
      payloadBytes: 2050,
    ),
    SyncRecord(
      id: 'Q-0002',
      type: 'scan',
      createdAt: at(8, 8),
      payloadBytes: 2050,
    ),
  ];

  // --------------------------------------------------------------- scanning
  static const String scannerInput = 'DataWedge intent';
  static const List<String> symbologies = <String>[
    'EAN-13',
    'GS1-128',
    'DataMatrix',
  ];
  static const String passFeedback = 'Beep + 1 buzz';
  static const String failFeedback = 'Double tone + 3 buzz';
  static const List<String> languages = <String>['Kiswahili', 'English'];
  static const int idleLockSeconds = 90;
  static const String deviceSerial = 'TC58-DAR-014';
  static const String appVersion = '3.8.2';
}
