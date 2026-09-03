import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_config.freezed.dart';

/// Shift and device-session policy.
@freezed
abstract class SessionConfig with _$SessionConfig {
  const factory SessionConfig({
    /// Languages the interface offers, in preference order.
    required List<String> languages,

    /// Seconds of inactivity before the device locks. Short, because a
    /// handheld gets put down on a pallet and walked away from.
    required int idleLockSeconds,
  }) = _SessionConfig;

  const SessionConfig._();

  /// `Kiswahili / English`
  String get languagesLabel => languages.join(' / ');

  String get idleLockLabel => '$idleLockSeconds s';
}
