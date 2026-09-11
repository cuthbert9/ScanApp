import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanapp/app/app.dart';
import 'package:scanapp/data/network_providers.dart';
import 'package:scanapp/features/loading/presentation/load_reconciliation_screen.dart';
import 'package:scanapp/features/loading/presentation/scan_screen.dart';
import 'package:scanapp/features/orders/presentation/loading_queue_screen.dart';
import 'package:scanapp/features/settings/presentation/settings_screen.dart';
import 'package:scanapp/features/sync/presentation/sync_screen.dart';

import 'support/fake_auth_repository.dart';

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

    final ProviderContainer container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(const FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

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

    // Settings reads four repositories in sequence — up to ~1.6 s of
    // artificial latency — and Settings is the last tab visited above, so its
    // final read can still be in flight here. Let it resolve before tearing
    // down, or the pending mock-latency timer fails teardown below.
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // The shell's `IndexedStack` never disposes a tab once visited, so the
    // Scan screen's door-timer `Timer.periodic` is still running. Unmount the
    // whole tree so it actually cancels — the test framework fails a
    // dangling periodic timer at teardown otherwise.
    await tester.pumpWidget(const SizedBox());
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

  testWidgets('every screen clears a simulated status bar', (
    WidgetTester tester,
  ) async {
    // A pinned dashboard has no header above it to push it down once it has
    // scrolled to the top — it collided with the status bar/notch until each
    // screen's `CustomScrollView` was wrapped in its own `SafeArea`. This
    // checks that guarantee directly: the scrollable viewport itself must
    // start below the inset, on every tab, regardless of scroll position.
    const double simulatedInset = 44;

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = portrait;
    tester.view.padding = const FakeViewPadding(top: simulatedInset);
    addTearDown(tester.view.reset);

    // Disposed explicitly at the end, not via addTearDown — the framework
    // checks for live handles before tear-downs run.
    final SemanticsHandle semantics = tester.ensureSemantics();

    final ProviderContainer container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(const FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ScanApp()),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    final Finder card = find.textContaining('Dodoma', findRichText: true);
    await tester.tap(card);
    await tester.pump(const Duration(milliseconds: 600));

    const Map<String, Type> tabScreens = <String, Type>{
      'Orders': LoadingQueueScreen,
      'Scan': ScanScreen,
      'Load': LoadReconciliationScreen,
      'Sync': SyncScreen,
      'Settings': SettingsScreen,
    };

    for (final MapEntry<String, Type> entry in tabScreens.entries) {
      await tester.tap(find.bySemanticsLabel(entry.key));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 1));

      final Rect viewportRect = tester.getRect(
        find
            .descendant(
              of: find.byType(entry.value),
              matching: find.byType(CustomScrollView),
            )
            .first,
      );
      expect(
        viewportRect.top,
        greaterThanOrEqualTo(simulatedInset),
        reason:
            '${entry.key} — scrollable viewport must start below the '
            'status bar, not just the header that scrolls out of it',
      );
    }

    semantics.dispose();

    // Settings is the last tab visited above and reads four repositories in
    // sequence — let its final read resolve before tearing down (see the
    // matching note in walkEveryTab).
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // Scan's door-timer keeps running once visited — see the note in
    // walkEveryTab.
    await tester.pumpWidget(const SizedBox());
  });
}
