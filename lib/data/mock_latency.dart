import 'dart:math';

/// Artificial round-trip time for every mock repository call.
///
/// Deliberate: without it every screen would resolve in the same frame and the
/// loading states would never be seen, let alone tested.
Future<void> mockLatency() {
  final int ms = 150 + Random().nextInt(251); // 150-400 ms
  return Future<void>.delayed(Duration(milliseconds: ms));
}
