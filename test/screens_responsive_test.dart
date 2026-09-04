import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanapp/app/app.dart';
import 'package:scanapp/features/auth/application/auth_controller.dart';

/// Rule 1c: every screen must survive every canvas the MC9450 can present.
///
/// Flutter reports a `RenderFlex overflowed` as a thrown error, so this turns
/// the yellow-and-black stripes into a test failure. It walks all five tabs at
/// each size rather than testing screens in isolation, because the shell's
/// chrome is part of what has to fit.
void main() {
  /// The real device, upright.
  const Size portrait = Size(320, 533);

  /// Rotated: only 320 dp of height.
  const Size landscape = Size(533, 320);

  /// Tab semantics labels, which are title-case and unique. The visible text is
  /// upper-case and collides with the summary strip's own `ORDERS` label.
  const List<String> tabs = <String>[
    'Orders',
    'Scan',
    'Load',
    'Sync',
    'Settings',
  ];

  Future<void> walkEveryTab(
    WidgetTester tester, {
    required Size size,
    double textScale = 1.0,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    // Disposed at the end of this helper, not via addTearDown: the framework
    // checks for live handles before tear-downs run.
    final SemanticsHandle semantics = tester.ensureSemantics();

    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(authControllerProvider.notifier).signIn();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const ScanApp(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull, reason: 'orders, first paint');

    // Open an order so Scan and Load have something to render.
    final Finder card = find.textContaining('Dodoma', findRichText: true);
    if (card.evaluate().isNotEmpty) {
      await tester.tap(card);
      await tester.pump(const Duration(milliseconds: 600));
    }

    for (final String tab in tabs) {
      final Finder finder = find.bySemanticsLabel(tab);
      if (finder.evaluate().isEmpty) continue;
      await tester.tap(finder);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: 'overflow on $tab');
    }

    semantics.dispose();
  }

  testWidgets('portrait 320x533', (WidgetTester tester) async {
    await walkEveryTab(tester, size: portrait);
  });

  testWidgets('landscape 533x320', (WidgetTester tester) async {
    await walkEveryTab(tester, size: landscape);
  });

  testWidgets('portrait at font scale 1.3', (WidgetTester tester) async {
    await walkEveryTab(tester, size: portrait, textScale: 1.3);
  });

  testWidgets('landscape at font scale 1.3', (WidgetTester tester) async {
    await walkEveryTab(tester, size: landscape, textScale: 1.3);
  });
}
