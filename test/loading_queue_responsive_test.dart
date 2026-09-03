import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanapp/core/design/design.dart';
import 'package:scanapp/features/orders/presentation/loading_queue_screen.dart';

/// Rule 1c verification: the loading queue must survive every canvas the
/// MC9450 can actually present.
///
/// Flutter reports a `RenderFlex overflowed` as a thrown error, so
/// `tester.takeException()` turns "the yellow-and-black stripes" into a test
/// failure. This is the cheap way to catch layout regressions that nobody would
/// think to re-check by hand.
void main() {
  Future<void> pumpQueue(
    WidgetTester tester, {
    required Size size,
    double textScale = 1.0,
    double keyboardInset = 0,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (BuildContext context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                viewInsets: EdgeInsets.only(bottom: keyboardInset),
              ),
              child: const LoadingQueueScreen(),
            ),
          ),
        ),
      ),
    );
    // The fake repository has a deliberate latency, so settle past it.
    await tester.pumpAndSettle();
  }

  /// The real device, upright.
  const Size portrait = Size(320, 533);

  /// Rotated: only 320 dp of height to work with.
  const Size landscape = Size(533, 320);

  testWidgets('renders the queue in portrait without overflow', (
    WidgetTester tester,
  ) async {
    await pumpQueue(tester, size: portrait);

    expect(find.text('Loading Queue'), findsOneWidget);
    expect(find.text('Dodoma Zonal Store'), findsOneWidget);
    expect(find.text('Morogoro Regional Medical Store'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('summary counts are derived from the orders', (
    WidgetTester tester,
  ) async {
    await pumpQueue(tester, size: portrait);

    // 3 orders, 14 + 19 + 8 = 41 units, 2 of them cold chain.
    expect(find.text('3'), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('the primary action targets the loading order with no tap', (
    WidgetTester tester,
  ) async {
    await pumpQueue(tester, size: portrait);

    // DO-2026-04417 is the one with status `loading`, so it is what the CTA
    // targets before the operator taps anything.
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('DO-2026-04417'), findsOneWidget);

    // The card shows it too, but inside AppMetaRow's Text.rich — plain
    // `find.text` does not see TextSpans, so the rich variant is needed.
    expect(
      find.textContaining('DO-2026-04417', findRichText: true),
      findsNWidgets(2),
    );
  });

  testWidgets('survives landscape, where height is scarce', (
    WidgetTester tester,
  ) async {
    await pumpQueue(tester, size: landscape);
    expect(tester.takeException(), isNull);
  });

  testWidgets('survives the on-screen keyboard', (WidgetTester tester) async {
    await pumpQueue(tester, size: portrait, keyboardInset: 250);
    expect(tester.takeException(), isNull);
  });

  testWidgets('survives font scale 1.3', (WidgetTester tester) async {
    await pumpQueue(tester, size: portrait, textScale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('survives landscape at font scale 1.3 together', (
    WidgetTester tester,
  ) async {
    await pumpQueue(tester, size: landscape, textScale: 1.3);
    expect(tester.takeException(), isNull);
  });
}
