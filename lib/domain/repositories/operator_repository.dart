import '../../core/result/result.dart';
import '../models/operator_profile.dart';

/// Basic operator profile information for the scanning app.
abstract interface class OperatorRepository {
  Future<Result<OperatorProfile>> byId(String operatorId);
}
