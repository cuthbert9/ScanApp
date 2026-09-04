import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_config.freezed.dart';

/// How this handheld is configured.
///
/// Read-only on screen: these come from the DataWedge profile and the managed
/// configuration deployed to the device, not from anything the operator sets.
@freezed
abstract class DeviceConfig with _$DeviceConfig {
  const factory DeviceConfig({
    /// Device asset tag, e.g. `TC58-DAR-014`.
    required String serial,

    /// Installed build, e.g. `3.8.2`.
    required String appVersion,

    /// Where decoded barcodes arrive from.
    required String scannerInput,

    /// Symbologies the profile has enabled.
    required List<String> symbologies,

    /// Haptic and audio response on a good read.
    required String passFeedback,

    /// Response on a rejected read. Deliberately unmistakable from
    /// [passFeedback] — an operator in ear defenders tells them apart by the
    /// buzz pattern alone.
    required String failFeedback,

    /// Languages the interface offers, in preference order.
    required List<String> languages,

    /// Seconds of inactivity before the device locks. Short, because a handheld
    /// gets put down on a pallet and walked away from.
    required int idleLockSeconds,
  }) = _DeviceConfig;

  const DeviceConfig._();

  /// `TC58-DAR-014 · APP 3.8.2`
  String get headerLabel => '$serial  ·  APP $appVersion';

  /// `EAN-13 · GS1-128 · DataMatrix`
  String get symbologiesLabel => symbologies.join('  ·  ');

  /// `Kiswahili / English`
  String get languagesLabel => languages.join(' / ');

  String get idleLockLabel => '$idleLockSeconds s';
}
