import 'package:freezed_annotation/freezed_annotation.dart';

part 'scanner_config.freezed.dart';

/// How the handheld's imager is configured.
///
/// Read-only on this screen: these come from the DataWedge profile deployed to
/// the device, not from anything the operator sets here.
@freezed
abstract class ScannerConfig with _$ScannerConfig {
  const factory ScannerConfig({
    /// Where decoded barcodes arrive from, e.g. `DataWedge intent`.
    required String input,

    /// Symbologies the profile has enabled.
    required List<String> symbologies,

    /// Haptic and audio response on a good read.
    required String passFeedback,

    /// Response on a rejected read. Deliberately unmistakable from
    /// [passFeedback] — an operator wearing ear defenders distinguishes these
    /// by the buzz pattern alone.
    required String failFeedback,
  }) = _ScannerConfig;

  const ScannerConfig._();

  /// `EAN-13 · GS1-128 · DataMatrix`
  String get symbologiesLabel => symbologies.join('  ·  ');
}
