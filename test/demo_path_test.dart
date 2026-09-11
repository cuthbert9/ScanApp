import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanapp/app/app.dart';
import 'package:scanapp/app/state/preferences_controller.dart';
import 'package:scanapp/app/state/sync_controller.dart';
import 'package:scanapp/data/network_providers.dart';
import 'package:scanapp/domain/models/display_choice.dart';
import 'package:scanapp/features/loading/presentation/load_reconciliation_screen.dart';
import 'package:scanapp/features/loading/presentation/scan_screen.dart';
import 'package:scanapp/features/orders/presentation/loading_queue_screen.dart';
import 'package:scanapp/features/settings/presentation/settings_screen.dart';
import 'package:scanapp/features/sync/presentation/sync_screen.dart';

import 'support/fake_auth_repository.dart';

/// The demo path, walked end to end through the real router and shell.
///
/// This is the test the whole mock layer exists for: it proves the five screens
/// share one source of truth, that a scan on one moves the figures on the
/// others, and that a seal removes the order from the queue.
///
/// It pumps with explicit durations rather than `pumpAndSettle`, because the
/// Scan screen runs a one-second door timer that never settles by design.
void main() {
  const Size portrait = Size(320, 533);

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = portrait;
    addTearDown(tester.view.reset);

    final ProviderContainer container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(const FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ScanApp()),
    );
    // Let the repositories' artificial latency resolve.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    return container;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));
  }

  /// Every screen is now one `CustomScrollView`, and the header/dashboard and
  /// bottom action bar scroll with it rather than staying pinned — so a
  /// widget near the bottom (an action button, a low list item) does not
  /// exist in the tree until it has actually scrolled into the cache extent.
  /// This drags the named screen's scroll view down until [target] is built,
  /// scoping the search to that screen because the shell's `IndexedStack`
  /// keeps every tab mounted at once.
  Future<void> scrollUntilVisible(
    WidgetTester tester,
    Type screenType,
    Finder target,
  ) async {
    final Finder scrollable = find
        .descendant(
          of: find.byType(screenType),
          matching: find.byType(CustomScrollView),
        )
        .first;
    await tester.dragUntilVisible(target, scrollable, const Offset(0, -220));
    await settle(tester);
  }

  /// Scroll position on a screen's `CustomScrollView` survives a tab switch —
  /// the shell keeps each branch's navigator alive — so a screen visited
  /// earlier in mid-scroll can come back exactly where it was left. Jumps it
  /// back to the top, where the header and dashboard actually are.
  Future<void> scrollToTop(WidgetTester tester, Type screenType) async {
    final Finder scrollable = find
        .descendant(
          of: find.byType(screenType),
          matching: find.byType(CustomScrollView),
        )
        .first;
    await tester.fling(scrollable, const Offset(0, 2000), 4000);
    await settle(tester);
  }

  testWidgets('the full demo path', (WidgetTester tester) async {
    final ProviderContainer container = await pumpApp(tester);

    // --- Orders -----------------------------------------------------------
    expect(find.text('Loading Queue'), findsOneWidget);
    expect(
      find.textContaining('Dodoma Zonal Store', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('3'), findsOneWidget, reason: 'three staged orders');
    expect(find.text('41'), findsOneWidget, reason: '14 + 19 + 8 units');

    // Tapping a card selects it; it must not navigate.
    await tester.tap(
      find.textContaining('Dodoma Zonal Store', findRichText: true),
    );
    await settle(tester);
    expect(find.text('Loading Queue'), findsOneWidget);

    // The "Open" bar scrolls in at the bottom of the queue now, rather than
    // staying pinned above the tab bar — scroll it into view.
    await scrollUntilVisible(tester, LoadingQueueScreen, find.text('Open'));
    expect(find.text('DO-2026-04417'), findsWidgets);

    // --- Open -> Scan -----------------------------------------------------
    await tester.tap(find.text('Open'));
    await settle(tester);

    expect(find.text('Scan & Verify'), findsOneWidget);
    expect(find.text('13/14'), findsOneWidget, reason: 'the progress ring');
    expect(
      find.textContaining('Zinc Sulfate', findRichText: true),
      findsOneWidget,
      reason: 'the held line opens the feed',
    );

    // --- Debug trigger ----------------------------------------------------
    final int pendingBefore = container.read(pendingSyncCountProvider);
    await tester.tap(find.byIcon(Icons.bolt));
    await settle(tester);

    expect(
      container.read(pendingSyncCountProvider),
      greaterThan(pendingBefore),
      reason: 'every scan enqueues a sync record, which moves the tab badge',
    );

    // --- Reconcile -> Load ------------------------------------------------
    // The scan field pins in place, but the feed below it can push the
    // Reconcile bar out of the initial viewport once there is enough of it.
    await scrollUntilVisible(tester, ScanScreen, find.text('Reconcile'));
    await tester.tap(find.text('Reconcile'));
    await settle(tester);

    expect(find.text('Load Reconciliation'), findsOneWidget);
    expect(find.text('14 units'), findsOneWidget);
    expect(find.text('13 units'), findsOneWidget);
    expect(find.text('92.9 %'), findsOneWidget);
    expect(find.textContaining('FEFO hold'), findsOneWidget);

    // --- Seal -------------------------------------------------------------
    await scrollUntilVisible(
      tester,
      LoadReconciliationScreen,
      find.text('Seal load'),
    );
    await tester.tap(find.text('Seal load'));
    await settle(tester);
    await settle(tester);

    // Back on Orders — mid-scroll from opening the order earlier, since the
    // shell kept that branch alive. Scroll back up to where the header is.
    await scrollToTop(tester, LoadingQueueScreen);

    // Back on Orders, and the sealed order has left the staged list.
    expect(find.text('Loading Queue'), findsOneWidget);
    expect(
      find.textContaining('Dodoma Zonal Store', findRichText: true),
      findsNothing,
      reason: 'a sealed order leaves the queue',
    );
    expect(find.text('2'), findsWidgets, reason: 'two orders remain');
  });

  testWidgets('the Scan tab with no order open offers a way back', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    // Straight to Scan without opening anything.
    await tester.tap(find.text('SCAN'));
    await settle(tester);

    expect(find.text('No order open'), findsOneWidget);
    expect(find.text('Choose one from the loading queue.'), findsOneWidget);

    await tester.tap(find.text('Go to loading queue'));
    await settle(tester);
    expect(find.text('Loading Queue'), findsOneWidget);
  });

  testWidgets('flushing clears the badge everywhere', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpApp(tester);
    expect(container.read(pendingSyncCountProvider), 2);

    await tester.tap(find.text('SYNC'));
    await settle(tester);
    expect(find.text('Offline Sync'), findsOneWidget);

    // "Flush queue now" now scrolls in at the bottom of the sync screen.
    await scrollUntilVisible(tester, SyncScreen, find.text('Flush queue now'));
    await tester.tap(find.text('Flush queue now'));
    // The push is deliberately slower than a read, so the state is visible.
    await tester.pump(const Duration(milliseconds: 1200));
    await settle(tester);

    // The state banner sits near the top, above the mode cards this test
    // scrolled past to reach the flush button.
    await scrollToTop(tester, SyncScreen);

    expect(container.read(pendingSyncCountProvider), 0);
    expect(find.text('UP TO DATE'), findsOneWidget);
  });

  testWidgets('choosing Night repaints the app without a restart', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpApp(tester);

    await tester.tap(find.text('SETTINGS'));
    // Settings reads four repositories in sequence, so up to ~1.6 s of
    // artificial latency before the body renders.
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    final MaterialApp before = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(before.themeMode, ThemeMode.system, reason: 'Auto is the default');

    // Settings is one `CustomScrollView` now (header, dashboard, body and
    // the Sign out/Done bar all scroll together), not a `ListView` wrapped by
    // pinned chrome. The shell's `IndexedStack` keeps every screen mounted,
    // so scope the finder to this one.
    await scrollUntilVisible(tester, SettingsScreen, find.text('Night'));
    expect(find.text('Night'), findsOneWidget);
    await tester.tap(find.text('Night'), warnIfMissed: true);
    await settle(tester);

    // Assert the preference too, so a missed tap is distinguishable from a
    // wiring failure between the preference and MaterialApp.
    expect(container.read(resolvedThemeChoiceProvider), ThemeChoice.night);

    final MaterialApp after = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(after.themeMode, ThemeMode.dark);
  });
}
