import '../../core/result/result.dart';
import '../models/app_remote_config.dart';

/// Server-controlled scanning app configuration.
abstract interface class AppConfigRepository {
  Future<Result<AppRemoteConfig>> current();
}
