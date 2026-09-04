import '../../core/result/result.dart';
import '../models/officer.dart';
import '../models/shift_stats.dart';

/// Who is signed in, and how their shift is going.
///
/// SWAP POINT — the real implementation reads the officer from the session and
/// the figures from the ERP's productivity endpoint.
abstract interface class OfficerRepository {
  Future<Result<Officer>> current();

  Future<Result<ShiftStats>> statsToday();
}
