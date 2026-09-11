import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_remote_config.freezed.dart';
part 'app_remote_config.g.dart';

/// Server-controlled scanning app configuration.
///
/// `GET /v2/scn/app/config`'s body shape has never been confirmed — no
/// example response exists yet, live or documented — so this deliberately
/// stays a raw passthrough rather than named fields that might not match.
/// Replace with typed fields once a real response has been seen.
@freezed
abstract class AppRemoteConfig with _$AppRemoteConfig {
  const factory AppRemoteConfig({
    @Default(<String, Object?>{}) Map<String, Object?> raw,
  }) = _AppRemoteConfig;

  factory AppRemoteConfig.fromJson(Map<String, Object?> json) =>
      AppRemoteConfig(raw: json);
}
