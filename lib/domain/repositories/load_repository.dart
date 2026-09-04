import '../../core/result/result.dart';
import '../models/load_seal.dart';

/// Seals a load and records what went on the truck.
///
/// SWAP POINT — the real implementation posts the seal to dispatch and receives
/// the amended manifest number back.
abstract interface class LoadRepository {
  /// Seals [docNo]: sets the order sealed, writes a [LoadSeal] and enqueues a
  /// sync record.
  ///
  /// Fails with a [ValidationException] when the order has a cold-chain
  /// excursion, or is already sealed.
  Future<Result<LoadSeal>> seal({required String docNo});

  /// The seal already written for [docNo], if any.
  Future<Result<LoadSeal?>> sealFor(String docNo);
}
