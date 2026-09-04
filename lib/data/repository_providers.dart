import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/load_repository.dart';
import '../domain/repositories/officer_repository.dart';
import '../domain/repositories/order_repository.dart';
import '../domain/repositories/scan_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/station_repository.dart';
import '../domain/repositories/sync_repository.dart';
import 'mock_backend.dart';
import 'mock_load_repository.dart';
import 'mock_officer_repository.dart';
import 'mock_order_repository.dart';
import 'mock_scan_repository.dart';
import 'mock_settings_repository.dart';
import 'mock_station_repository.dart';
import 'mock_sync_repository.dart';

part 'repository_providers.g.dart';

/// **The swap points.**
///
/// Every repository is provided in exactly one place, and every screen reads
/// the interface. Point these at HTTP implementations and nothing above them
/// moves — no widget, no controller, no test that overrides a provider.
///
/// All seven are `keepAlive`, because [MockBackend] is stateful: a fresh
/// instance would silently restore the seed and undo every scan.

/// The single in-memory store all seven repositories share.
@Riverpod(keepAlive: true)
MockBackend mockBackend(Ref ref) => MockBackend();

@Riverpod(keepAlive: true)
OrderRepository orderRepository(Ref ref) =>
    MockOrderRepository(ref.watch(mockBackendProvider));

@Riverpod(keepAlive: true)
ScanRepository scanRepository(Ref ref) =>
    MockScanRepository(ref.watch(mockBackendProvider));

@Riverpod(keepAlive: true)
LoadRepository loadRepository(Ref ref) =>
    MockLoadRepository(ref.watch(mockBackendProvider));

@Riverpod(keepAlive: true)
SyncRepository syncRepository(Ref ref) =>
    MockSyncRepository(ref.watch(mockBackendProvider));

@Riverpod(keepAlive: true)
StationRepository stationRepository(Ref ref) =>
    MockStationRepository(ref.watch(mockBackendProvider));

@Riverpod(keepAlive: true)
OfficerRepository officerRepository(Ref ref) =>
    MockOfficerRepository(ref.watch(mockBackendProvider));

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    MockSettingsRepository(ref.watch(mockBackendProvider));
